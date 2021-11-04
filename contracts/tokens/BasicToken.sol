// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:security-contact security@gitvern.org
contract BasicToken is ERC20 {
    constructor() ERC20("DAO Token", "DAO") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}