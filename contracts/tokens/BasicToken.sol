// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:security-contact security@gitvern.org
contract BasicToken is ERC20 {
    constructor(uint256 supply) ERC20("DAO Token", "DAO") {
        _mint(msg.sender, supply);
    }
}