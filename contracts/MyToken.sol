//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyToken {
    string public constant name = "MyToken";
    string public constant symbol = "MTK";
    uint256 public totalSupply;
    address public owner;
    constructor(uint256 _totalSupply, address _owner) {
        totalSupply = _totalSupply;
        owner = _owner;
    }
}
