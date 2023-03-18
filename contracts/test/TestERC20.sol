// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {

    constructor(string memory name_, string memory symbol_, uint256 mint_)ERC20(name_, symbol_){
        _mint(msg.sender, mint_);
    }
}
