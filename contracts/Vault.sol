//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


struct Deposit {
    uint256 depositAt;
    uint256 amountWei;
}

error TimeLocked(uint256 timeLeft);
error NoDeposit();

contract Vault {

    mapping (address => Deposit) private _deposits;
    address public owner;
    uint256 public lockTime;

    constructor(uint256 _lockTime){
        owner = msg.sender;
        lockTime = _lockTime;
    }

    function withdraw() external {
        Deposit memory userDeposit = _deposits[msg.sender];
        if (userDeposit.depositAt == 0) {
            revert NoDeposit();
        }
        if (block.timestamp < userDeposit.depositAt + lockTime) {
            revert TimeLocked(userDeposit.depositAt + lockTime - block.timestamp);
        }
        delete _deposits[msg.sender];
        payable(msg.sender).transfer(userDeposit.amountWei);
    }

    function deposit() public payable {
        Deposit memory existingDeposit = _deposits[msg.sender];
        // If the user has already deposited, we need to add the new amount to the existing deposit
        // Otherwise, we just create a new deposit
        // Since everything is zero-initialized, we treat a deposit of 0 as a non-existing deposit
        // If the users updates their deposit, the lock time is reset
        _deposits[msg.sender] = Deposit(
            block.timestamp,
            existingDeposit.amountWei + msg.value
        );
    }

    // Forward everything to deposit
    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

}