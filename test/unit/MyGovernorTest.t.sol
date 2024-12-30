// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {GovTokenMock} from "test/mocks/GovTokenMock.sol";

import {MyGovernor} from "src/MyGovernor.sol";
import {TimeLock} from "src/TimeLock.sol";
import {Box} from "src/Box.sol";

contract MyGovernorTest is Test {
    GovTokenMock token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50_400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        token = new GovTokenMock();
        token.mint(VOTER, 100e18);

        vm.prank(VOTER);
        token.delegate(VOTER); // delegate voting power

        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(token, timelock);
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        string memory description = "Store 1 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSelector(Box.store.selector, valueToStore);
        addressesToCall.push(address(box));
        values.push(0);
        functionCalls.push(encodedFunctionCall);

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(addressesToCall, values, functionCalls, description);

        assert(governor.state(proposalId) == IGovernor.ProposalState.Pending);
        assertEq(governor.proposalSnapshot(proposalId), VOTING_DELAY + 1);
        assertEq(governor.proposalDeadline(proposalId), VOTING_PERIOD + VOTING_DELAY + 1);

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        assert(governor.state(proposalId) == IGovernor.ProposalState.Active);

        // 2. Vote
        string memory reason = "I like a do da cha cha";
        uint8 voteWay = 1; // 0 = Against, 1 = For, 2 = Abstain for this example
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        assert(governor.state(proposalId) == IGovernor.ProposalState.Succeeded);

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(addressesToCall, values, functionCalls, descriptionHash);

        assert(box.retrieve() == valueToStore);
    }
}
