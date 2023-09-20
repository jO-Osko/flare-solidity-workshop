//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


struct DepositData {
    uint256 depositAt;
    uint256 amountWei;
}

error TimeLocked(uint256 timeLeft);
error InvalidRecipient();
error NoDeposit();

contract ImprovedVault {

    event Deposit(address indexed sender, uint256 amountWei);
    event Withdraw(address indexed sender, address indexed target, uint256 amountWei);
    event AllowRecipient(address indexed source, address indexed recipient, bool allowed);

    mapping (address => mapping(address => uint256)) public allowedRecipients;
    mapping (address => uint256[]) public withdrawals;

    mapping (address => DepositData) private _deposits;

    address public owner;
    uint256 public lockTime;

    constructor(uint256 _lockTime){
        owner = msg.sender;
        lockTime = _lockTime;
    }


    function allowRecipient(address recipient) external {
        allowedRecipients[msg.sender][recipient] = 1;
        emit AllowRecipient(msg.sender, recipient, true);
    }

    function disallowRecipient(address recipient) external {
        allowedRecipients[msg.sender][recipient] = 0;
        emit AllowRecipient(msg.sender, recipient, false);
    }

    function withdrawSloppy(address[] memory targets) external {
        DepositData memory userDeposit = _deposits[msg.sender];
        if (userDeposit.depositAt == 0) {
            revert NoDeposit();
        }
        if (block.timestamp < userDeposit.depositAt + lockTime) {
            revert TimeLocked(userDeposit.depositAt + lockTime - block.timestamp);
        }

        address [] memory allowed = new address [](targets.length); 
        uint256 numAllowed = 0;
        for(uint256 i = 0; i < targets.length; i++){
            if(allowedRecipients[msg.sender][targets[i]] != 0){
                allowed[numAllowed] = (targets[i]);
                numAllowed++;
            }
        }

        if(numAllowed == 0){
            payable(msg.sender).transfer(userDeposit.amountWei);
            emit Withdraw(msg.sender, msg.sender, userDeposit.amountWei);
        } else {
            uint256 perAddress = userDeposit.amountWei / numAllowed;
            uint256 remainder = userDeposit.amountWei % numAllowed;
            
            for(uint256 i = 0; i < numAllowed; i++){
                payable(allowed[i]).transfer(perAddress);
                emit Withdraw(msg.sender, allowed[i], perAddress);
            }
            if(remainder > 0){
                payable(msg.sender).transfer(remainder);
                emit Withdraw(msg.sender, msg.sender, userDeposit.amountWei);
            }
        }
        withdrawals[msg.sender].push(block.timestamp);
    }

    function withdraw(address[] memory targets) public {
        DepositData memory userDeposit = _deposits[msg.sender];
        if (userDeposit.depositAt == 0) {
            revert NoDeposit();
        }
        if (block.timestamp < userDeposit.depositAt + lockTime) {
            revert TimeLocked(userDeposit.depositAt + lockTime - block.timestamp);
        }
        for(uint256 i = 0; i < targets.length; i++){
            if(allowedRecipients[msg.sender][targets[i]] == 0){
                revert InvalidRecipient();
            }
        }
        delete _deposits[msg.sender];

        if(targets.length == 0){
            payable(msg.sender).transfer(userDeposit.amountWei);
            emit Withdraw(msg.sender, msg.sender, userDeposit.amountWei);
        } else {
            uint256 perAddress = userDeposit.amountWei / targets.length;
            uint256 remainder = userDeposit.amountWei % targets.length;
            
            for(uint256 i = 0; i < targets.length; i++){
                payable(targets[i]).transfer(perAddress);
                emit Withdraw(msg.sender, targets[i], perAddress);
            }
            if(remainder > 0){
                payable(msg.sender).transfer(remainder);
                emit Withdraw(msg.sender, msg.sender, userDeposit.amountWei);
            }
        }
        withdrawals[msg.sender].push(block.timestamp);
    }

    function deposit() public payable {
        DepositData memory existingDeposit = _deposits[msg.sender];
        // If the user has already deposited, we need to add the new amount to the existing deposit
        // Otherwise, we just create a new deposit
        // Since everything is zero-initialized, we treat a deposit of 0 as a non-existing deposit
        // If the users updates their deposit, the lock time is reset
        _deposits[msg.sender] = DepositData(
            block.timestamp,
            existingDeposit.amountWei + msg.value
        );
        emit Deposit(msg.sender, msg.value);
    }

    // Forward everything to deposit
    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

}