// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {GovToken} from "src/GovToken.sol";

contract GovTokenMock is GovToken {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
