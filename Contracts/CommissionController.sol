// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./.deps/npm/@openzeppelin/contracts/access/Ownable.sol";
import "./.deps/npm/@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    PurchasePercentage public _purchasePercentage =
        PurchasePercentage(100, 75, 50);

    CommissionPercentage public _commissionPercentage =
        CommissionPercentage(300, 250, 200);

    IERC20 public _token;
    address public _admin;
    address public _reservesContracts;
    bool public _commissionTransfer;
    uint256 public _maxContribLimit;


    mapping(address => bool) public _salesAgents;
    mapping(address => bool) public _requester;
    mapping(address => uint256) public _salesAgentsCommission;

    event CommissionTransferUpdated(bool status);
    event SalesAgentUpdated(address salesAgent, bool status);
    event RequesterUpdated(address requester, bool status);
    event CommissionDistributed(address salesAgent, uint256 amount);

    constructor(
        address admin,
        address token,
        address reservesContracts
    ) Ownable(msg.sender) {
        _admin = admin;
        _token = IERC20(token);
        _reservesContracts = reservesContracts;
        _salesAgents[_reservesContracts] = true;
        _maxContribLimit = token._marketAccount() / 200; // 0.5% of total market volume

        // _commissionTransfer is by-default false
    }

    function requestCommission(
        address salesAgent,
        uint256 sellingAmount
    ) external {
        if(!_commissionTransfer) return;

        require(_requester[msg.sender], "Not authorised");
        if (salesAgent == address(0)) salesAgent = _reservesContracts;
        require(_salesAgents[salesAgent], "Not an agent");

        uint256 commissionAmount;
        uint256 purcahsePercentage = (sellingAmount * 100) / _maxContribLimit;

        if (
            purcahsePercentage <= _purchasePercentage.pp1 &&
            purcahsePercentage >= _purchasePercentage.pp2
        ) {
            commissionAmount = (sellingAmount * _commissionPercentage.cp1) / 10000;
        } else if (
            purcahsePercentage < _purchasePercentage.pp2 &&
            purcahsePercentage >= _purchasePercentage.pp3
        ) {
            commissionAmount = (sellingAmount * _commissionPercentage.cp2) / 10000; // add 18 zeros accordingly
        } else {
            commissionAmount = (sellingAmount * _commissionPercentage.cp3) / 10000;
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
        _requester[requester] = status;
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
     * @notice Allows the owner to set the maximum contribution limit.
     * @param denominator Denominator to calculate the maximum contribution limit.
     */
    function setMaxContribLimit(uint256 denominator) external onlyOwner {
        maxContribLimit = token._marketAccount() / denominator;
    }
}
