// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    PurchasePercentage public purchasePercentage =
        PurchasePercentage(100, 75, 50);

    CommissionPercentage public commissionPercentage =
        CommissionPercentage(300, 250, 200);

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

        // _commissionTransfer is by-default false
    }

    function requestCommission(
        address _salesAgent,
        uint256 _sellingAmount
    ) external {
        if (!commissionTransfer) return;

        require(requester[msg.sender], "Not authorised");
        if (salesAgent == address(0)) salesAgent = _reservesContracts;
        require(_salesAgents[salesAgent], "Not an agent");

        uint256 commissionAmount;
        uint256 purcahsePercentage = (sellingAmount * 100) / _maxContribLimit;

        if (
            purcahsePercentage <= _purchasePercentage.pp1 &&
            purcahsePercentage >= _purchasePercentage.pp2
        ) {
            commissionAmount =
                (sellingAmount * _commissionPercentage.cp1) /
                10000;
        } else if (
            purcahsePercentage < _purchasePercentage.pp2 &&
            purcahsePercentage >= _purchasePercentage.pp3
        ) {
            commissionAmount =
                (sellingAmount * _commissionPercentage.cp2) /
                10000; // add 18 zeros accordingly
        } else {
            commissionAmount =
                (sellingAmount * _commissionPercentage.cp3) /
                10000;
        }

        _salesAgentsCommission[salesAgent] += commissionAmount;
        _token.transfer(salesAgent, commissionAmount);

        emit CommissionDistributed(salesAgent, commissionAmount);
    }

    /**
     * @notice Allows the admin to set the status of a requester contract.
     * @param requester Address of the requester contract.
     * @param status Boolean status of the requester contract.
     */
    function setRequester(address requester, bool status) external {
        require(_admin == msg.sender, "Not Admin");
        requester[requester] = status;
        emit RequesterUpdated(requester, status);
    }

    /**
     * @notice Allows the admin to set the status of a sales agent.
     * @param salesAgent Address of the sales agent.
     * @param status Boolean status of the sales agent.
     */
    function setSalesAgents(address salesAgent, bool status) external {
        require(_admin == msg.sender, "Not Admin");
        _salesAgents[salesAgent] = status;
        emit SalesAgentUpdated(salesAgent, status);
    }

    function setCommissionTransfer(bool status) external {
        require(_admin == msg.sender, "Not Admin");
        _commissionTransfer = status;
        emit CommissionTransferUpdated(status);
    }

    /**
     * @notice Allows the owner to withdraw Token from the contract.
     * @param amount Amount of Token to withdraw.
     * @param memo Memo or description of the withdrawal.
     */
    function withdrawToken(
        address token,
        uint256 amount,
        string memory memo
    ) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @notice Allows the owner to deposit tokens into the contract.
     * @param tokenAmount Amount of tokens to deposit.
     */
    function depositTokens(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Zero amount");
        require(
            token.allowance(msg.sender, address(this)) >= tokenAmount,
            "Low allowance"
        );

        token.transferFrom(msg.sender, address(this), tokenAmount);
    }

    /**
     * @notice Allows the owner to remove ERC20 tokens from the contract.
     * @param _token Address of the ERC20 token contract.
     * @param tokenAmount Amount of tokens to remove.
     */
    function removeERC20Tokens(
        address _token,
        uint256 tokenAmount
    ) external onlyOwner {
        require(tokenAmount > 0, "Zero amount");
        require(
            IShare(_token).balanceOf(address(this)) >= tokenAmount,
            "Low token balance"
        );

        IShare(_token).transfer(msg.sender, tokenAmount);
    }
    /**
     * @notice Allows the owner to set the maximum contribution limit.
     * @param denominator Denominator to calculate the maximum contribution limit.
     */
    function setMaxContribLimit(uint256 denominator) external onlyOwner {
        maxContribLimit = token.marketAccount() / denominator;
    }
}
