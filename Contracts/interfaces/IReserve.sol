// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IReserve {
    function deposit(uint256 amount, string memory memo) external;
    function withdrawForInvestment(uint256 amount, string memory memo) external;
}

