// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CommissionController is Ownable{
    address public admin;
    IERC20 public token;
    
    mapping(address => bool) public salesAgents;
    mapping(address => uint256) public salesAgentsCommission;

    constructor(address _admin, address _token) Ownable(msg.sender){
        admin = _admin;
        token = IERC20(_token);
    }

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

    /**
     * @notice Allows the owner to set the status of a sales agent.
     * @param salesAgent Address of the sales agent.
     * @param status Boolean status of the sales agent.
     */
    function setSalesAgents(address salesAgent, bool status) external onlyOwner {
        salesAgents[salesAgent] = status;
        emit SalesAgentUpdated(salesAgent, status);
    }
}

