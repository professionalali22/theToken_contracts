// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IShare.sol";

/**
 * @title  AirdropShare Contract
 * @notice This contract facilitates airdrops of SHARE tokens to holders and liquidity providers (LPs). It records transaction details
 *         including user addresses, transaction amounts, memos, and timestamps for both deposit and airdrop actions.
 *
 * Requirements:
 *
 * - The contract must be initialized with the SHARE token address and the USDT token address.
 * - The owner can airdrop tokens based on user holdings or LP token balances and can also withdraw tokens.
 */

contract AirdropShare is Ownable {
    IShare public token;
    IShare public usdt;

    struct Memo {
        address user;
        uint256 amount;
        string memo;
        uint256 timestamp;
    }

    Memo[] public lPProviderAirdropMemos;
    Memo[] public holderAirdropMemos;

    event Deposit(address indexed from, uint256 amount, string memo); // Event emitted on deposit
    event Withdraw(address indexed to, uint256 amount, string memo); // Event emitted on withdrawal

    /**
     * @notice Constructor to initialize the contract with the SHARE token and USDT token addresses.
     * @param _token Address of the SHARE token contract.
     * @param _usdt Address of the USDT token contract.
     */
    constructor(address _token, address _usdt) Ownable(msg.sender) {
        token = IShare(_token);
        usdt = IShare(_usdt);
    }

    /**
     * @notice Allows users to deposit SHARE tokens into the contract.
     * Users must approve the specified amount to this contract before calling this method.
     * @param amount Amount of SHARE tokens to deposit.
     * @param memo Memo or description of the deposit.
     */
    function deposit(uint256 amount, string memory memo) external {
        require(amount > 0, "Amount must be > 0");
        token.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount, memo);
    }

    /**
     * @notice Allows the owner to airdrop SHARE tokens to holders based on their holdings.
     * @param shareHolders Array of SHARE token holder addresses.
     * @param amount Total amount of SHARE tokens to be airdropped.
     * @param memo Memo or description of the airdrop.
     */
    function airdrop(
        address[] memory shareHolders,
        uint256 amount,
        string memory memo
    ) external onlyOwner {
        uint256 marketAccount = token.marketAccount();

        for (uint256 i = 0; i < shareHolders.length; i++) {
            address user = shareHolders[i];
            uint256 balance = token.balanceOf(user);
            uint256 dividend = (balance * amount) / marketAccount; // Calculate dividend based on holding percentage
            require(token.transfer(user, dividend), "Transfer failed");
        }

        holderAirdropMemos.push(
            Memo(msg.sender, amount, memo, block.timestamp)
        );
    }

    /**
     * @notice Allows the owner to airdrop SHARE tokens to LP providers based on their LP token balances.
     * @param exchange Address of the Uniswap V2 pair contract.
     * @param lPProviders Array of LP provider addresses.
     * @param amount Total amount of SHARE tokens to be airdropped.
     * @param memo Memo or description of the airdrop.
     */
    function airdropLPProvider(
        address exchange,
        address[] memory lPProviders,
        uint256 amount,
        string memory memo
    ) external onlyOwner {
        IUniswapV2Pair _exchange = IUniswapV2Pair(exchange);
        address token0 = _exchange.token0();
        address token1 = _exchange.token1();

        require(
            (token0 == address(token) || token0 == address(usdt)) &&
                (token1 == address(token) || token1 == address(usdt)),
            "Invalid exchange"
        );

        (uint112 reserve0, uint112 reserve1, ) = _exchange.getReserves();
        require(reserve0 > 0 && reserve1 > 0, "Zero reserves");

        uint256 totalSupply = _exchange.totalSupply();

        for (uint256 i = 0; i < lPProviders.length; i++) {
            address user = lPProviders[i];
            uint256 balance = _exchange.balanceOf(user);
            uint256 dividend = (balance * amount) / totalSupply; // Calculate dividend based on LP token balance
            require(token.transfer(user, dividend), "Transfer failed");
        }

        lPProviderAirdropMemos.push(
            Memo(msg.sender, amount, memo, block.timestamp)
        );
    }

    /**
     * @notice Allows the owner to withdraw tokens from the contract.
     * @param _token Address of the token contract to withdraw.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(
            IERC20(_token).balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        IERC20(_token).transfer(msg.sender, amount);
    }

    /**
     * @notice Retrieves all holder airdrop memos.
     * @return Array of holder airdrop memos.
     */
    function getHolderAirdropMemos() external view returns (Memo[] memory) {
        return holderAirdropMemos;
    }
}
