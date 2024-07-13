// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CommissionController Contract
 * @notice This contract manages commissions for sales agents and handles token distribution.
 * 
 * Requirements:
 * 
 * - The contract must be initialized with the admin address, token address, and reserves contract address.
 * - Only the admin can update requester and sales agent statuses.
 * - The owner can deposit and withdraw tokens.
 */

contract CommissionController is Ownable {
    struct PurchasePercentage {
        uint256 pp1;
        uint256 pp2;
        uint256 pp3;
    }

    struct CommissionPercentage {
        uint256 cp1;
        uint256 cp2;
        uint256 cp3;
    }

    PurchasePercentage public purchasePercentage = PurchasePercentage(100, 75, 50);
    CommissionPercentage public commissionPercentage = CommissionPercentage(300, 250, 200);

    IERC20 public token;
    address public admin;
    address public reservesContracts;
    bool public commissionTransfer;
    uint256 public maxContribLimit;

    mapping(address => bool) public salesAgents;
    mapping(address => bool) public requester;
    mapping(address => uint256) public salesAgentsCommission;

    event CommissionTransferUpdated(bool status);
    event SalesAgentUpdated(address salesAgent, bool status);
    event RequesterUpdated(address requester, bool status);
    event CommissionDistributed(address salesAgent, uint256 amount);

    /**
     * @notice Constructor to initialize the contract with admin, token, and reserves contract addresses.
     * @param _admin Address of the admin.
     * @param _token Address of the token contract.
     * @param _reservesContracts Address of the reserves contract.
     */
    constructor(
        address _admin,
        address _token,
        address _reservesContracts
    ) Ownable(msg.sender) {
        admin = _admin;
        token = IERC20(_token);
        reservesContracts = _reservesContracts;
        salesAgents[_reservesContracts] = true;
        maxContribLimit = token.marketAccount() / 200; // 0.5% of total market volume
    }

    /**
     * @notice Request commission for a sales agent based on the selling amount.
     * @param _salesAgent Address of the sales agent.
     * @param _sellingAmount Amount of tokens sold.
     */
    function requestCommission(
        address _salesAgent,
        uint256 _sellingAmount
    ) external {
        if (!commissionTransfer) return;

        require(requester[msg.sender], "Not authorised");
        if (_salesAgent == address(0)) _salesAgent = reservesContracts;
        require(salesAgents[_salesAgent], "Not an agent");

        uint256 commissionAmount;
        uint256 purchasePercentage = (_sellingAmount * 100) / maxContribLimit;

        if (
            purchasePercentage <= purchasePercentage.pp1 &&
            purchasePercentage >= purchasePercentage.pp2
        ) {
            commissionAmount =
                (_sellingAmount * commissionPercentage.cp1) /
                10000;
        } else if (
            purchasePercentage < purchasePercentage.pp2 &&
            purchasePercentage >= purchasePercentage.pp3
        ) {
            commissionAmount =
                (_sellingAmount * commissionPercentage.cp2) /
                10000;
        } else {
            commissionAmount =
                (_sellingAmount * commissionPercentage.cp3) /
                10000;
        }

        salesAgentsCommission[_salesAgent] += commissionAmount;
        token.transfer(_salesAgent, commissionAmount);

        emit CommissionDistributed(_salesAgent, commissionAmount);
    }

    /**
     * @notice Allows the admin to set the status of a requester contract.
     * @param _requester Address of the requester contract.
     * @param status Boolean status of the requester contract.
     */
    function setRequester(address _requester, bool status) external {
        require(admin == msg.sender, "Not Admin");
        requester[_requester] = status;
        emit RequesterUpdated(_requester, status);
    }

    /**
     * @notice Allows the admin to set the status of a sales agent.
     * @param _salesAgent Address of the sales agent.
     * @param status Boolean status of the sales agent.
     */
    function setSalesAgents(address _salesAgent, bool status) external {
        require(admin == msg.sender, "Not Admin");
        salesAgents[_salesAgent] = status;
        emit SalesAgentUpdated(_salesAgent, status);
    }

    /**
     * @notice Allows the admin to enable or disable commission transfers.
     * @param status Boolean status of the commission transfer.
     */
    function setCommissionTransfer(bool status) external {
        require(admin == msg.sender, "Not Admin");
        commissionTransfer = status;
        emit CommissionTransferUpdated(status);
    }

    /**
     * @notice Allows the owner to withdraw tokens from the contract.
     * @param _token Address of the token contract.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(IERC20(_token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(_token).transfer(msg.sender, amount);
    }

    /**
     * @notice Allows the owner to deposit tokens into the contract.
     * @param tokenAmount Amount of tokens to deposit.
     */
    function depositTokens(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Zero amount");
        require(token.allowance(msg.sender, address(this)) >= tokenAmount, "Low allowance");

        token.transferFrom(msg.sender, address(this), tokenAmount);
    }

    /**
     * @notice Allows the owner to remove ERC20 tokens from the contract.
     * @param _token Address of the ERC20 token contract.
     * @param tokenAmount Amount of tokens to remove.
     */
    function removeERC20Tokens(address _token, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Zero amount");
        require(IERC20(_token).balanceOf(address(this)) >= tokenAmount, "Low token balance");

        IERC20(_token).transfer(msg.sender, tokenAmount);
    }

    /**
     * @notice Allows the owner to set the maximum contribution limit.
     * @param denominator Denominator to calculate the maximum contribution limit.
     */
    function setMaxContribLimit(uint256 denominator) external onlyOwner {
        maxContribLimit = token.marketAccount() / denominator;
    }
}
