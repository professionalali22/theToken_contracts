// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title  Reserve Contract
 * @notice This contract allows users to deposit and withdraw USDT tokens. It records transaction details including user addresses,
 *         transaction amounts, memos, and timestamps for both deposits and withdrawals. The contract owner can withdraw funds for
 *         business investment purposes.
 * 
 * Requirements:
 *
 * - Ensure sufficient USDT allowance is approved for this contract to facilitate deposits.
 */

contract Reserve is Ownable {
    IERC20 public usdt;

    struct Memo {
        address user;       // Address of the user involved in the transaction
        uint256 amount;     // Amount of USDT involved in the transaction
        string memo;        // Memo or description related to the transaction
        uint256 timestamp;  // Timestamp of the transaction
    }

    Memo[] public depositMemos;   // Array to store deposit memos
    Memo[] public withdrawMemos;  // Array to store withdraw memos

    event Deposit(address indexed from, uint256 amount, string memo);    // Event emitted on deposit
    event Withdraw(address indexed to, uint256 amount, string memo);     // Event emitted on withdrawal

    /**
     * @notice Constructor to initialize the contract with the USDT token address.
     * @param _usdt Address of the USDT token contract.
     */
    constructor(IERC20 _usdt) Ownable(msg.sender) {
        usdt = _usdt;
    }

    /**
     * @notice Allows users to deposit USDT into the contract.
     * @param amount Amount of USDT to deposit.
     * @param memo Memo or description of the deposit.
     */
    function deposit(uint256 amount, string memory memo) external {
        require(amount > 0, "Amount must be greater than zero");
        usdt.transferFrom(msg.sender, address(this), amount);
        
        // Add deposit memo to array
        depositMemos.push(Memo(msg.sender, amount, memo, block.timestamp));
        
        emit Deposit(msg.sender, amount, memo);
    }

    /**
     * @notice Allows the owner to withdraw USDT from the contract for business investment.
     * @param amount Amount of USDT to withdraw.
     * @param memo Memo or description of the withdrawal.
     */
    function withdrawForInvestment(uint256 amount, string memory memo) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(usdt.balanceOf(address(this)) >= amount, "Insufficient balance");
        usdt.transfer(msg.sender, amount);
        
        // Add withdraw memo to array
        withdrawMemos.push(Memo(msg.sender, amount, memo, block.timestamp));
        
        emit Withdraw(msg.sender, amount, memo);
    }

    /**
     * @notice Allows the owner to withdraw Token from the contract.
     * @param amount Amount of Token to withdraw.
     * @param memo Memo or description of the withdrawal.
     */
    function withdrawToken(address token, uint256 amount, string memory memo) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(token).transfer(msg.sender, amount);
        
        // Add withdraw memo to array
        withdrawMemos.push(Memo(msg.sender, amount, memo, block.timestamp));
        
        emit Withdraw(msg.sender, amount, memo);
    }

    /**
     * @notice Retrieves all deposit memos.
     * @return Array of deposit memos.
     */
    function getDepositMemos() external view returns (Memo[] memory) {
        return depositMemos;
    }

    /**
     * @notice Retrieves all withdraw memos.
     * @return Array of withdraw memos.
     */
    function getWithdrawMemos() external view returns (Memo[] memory) {
        return withdrawMemos;
    }
}