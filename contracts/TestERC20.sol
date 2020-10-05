// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor (address[] memory c) public {
        for (uint i = 0; i < c.length; i++) {
            _mint(c[i], 1000000);
        }
    }
}