// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

error A();
error B(uint256 x);
error C(uint256 b, string some);


contract Tester {

    
    function revertA() public{
        revert A();
    }

    function revertB() public{
        revert B(block.timestamp);
    }

    function errorC() public {
        revert C(10, "sdasas");
    }

    function revertMsg() public {
        revert("generic error");
    }

}