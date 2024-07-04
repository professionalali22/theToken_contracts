// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICommissionController {
    function requestCommission(
        address salesAgent,
        uint256 purcahsePercentage
    ) external;

    function _maxContribLimit()external view returns(uint256);
}
