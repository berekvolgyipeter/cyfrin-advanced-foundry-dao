// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @dev inheritance:
 *     TimelockController: Contract module which acts as a timelocked controller. When set as the
 *         owner of an `Ownable` smart contract, it enforces a timelock on all
 *         `onlyOwner` maintenance operations. This gives time for users of the
 *         controlled contract to exit before a potentially dangerous maintenance
 *         operation is applied.
 */
contract TimeLock is TimelockController {
    /**
     * @param minDelay: initial minimum delay in seconds for operations
     * @param proposers: accounts to be granted proposer and canceller roles
     * @param executors: accounts to be granted executor role
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    )
        // msg.sender: optional account to be granted admin role; disable with zero address
        TimelockController(minDelay, proposers, executors, msg.sender)
    {}
}
