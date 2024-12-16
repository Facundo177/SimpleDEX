// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenA is ERC20, ERC20Permit {
    address public owner;

    constructor(address _owner) ERC20("TokenA", "TA") ERC20Permit("TokenA") {
        owner = _owner;
        _mint(owner, 10000 * 10 ** decimals());
    }
}