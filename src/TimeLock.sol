// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

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
