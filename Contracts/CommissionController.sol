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

    PurchasePercentage public purchasePercentage =
        PurchasePercentage(100, 75, 50);
    CommissionPercentage public commissionPercentage =
        CommissionPercentage(300, 250, 200);

    address public _admin;
    IERC20 public _token;

    mapping(address => bool) public _salesAgents;
    mapping(address => bool) public _requester;
    mapping(address => uint256) public _salesAgentsCommission;

    event SalesAgentUpdated(address salesAgent, bool status);
    event RequesterUpdated(address requester, bool status);
    event CommissionDistributed(address salesAgent, uint256 amount);

    constructor(
        address admin,
        address token,
        address reservesContracts
    ) Ownable(msg.sender) {
        admin = admin;
        token = IERC20(token);
        _salesAgents[reservesContracts] = true;
    }

    function requestCommission(
        address salesAgent,
        uint256 sellingAmount
    ) external {
        require(_requester[msg.sender], "Not authorised");
        if (salesAgent == address(0)) salesAgent = reservesContracts;
        require(_salesAgents[salesAgent], "Not an agent");

        uint256 commissionAmount;
        if (
            (tokenAmount * 100) / maxContribLimit <= purchasePercentage.pp1 &&
            (tokenAmount * 100) / maxContribLimit >= purchasePercentage.pp2
        ) {
            commissionAmount = (tokenAmount * commissionPercentage.cp1) / 10000;
        } else if (
            (tokenAmount * 100) / maxContribLimit < purchasePercentage.pp2 &&
            (tokenAmount * 100) / maxContribLimit >= purchasePercentage.pp3
        ) {
            commissionAmount = (tokenAmount * commissionPercentage.cp2) / 10000;
        } else {
            commissionAmount = (tokenAmount * commissionPercentage.cp3) / 10000;
        }

        salesAgentsCommission[salesAgent] += commissionAmount;
        token.transfer(salesAgent, commissionAmount);

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
}
