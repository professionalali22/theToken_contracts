// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/security/Pausable.sol";
import "./uniswap/v2-periphery/contracts/IUniswapV2Router02.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/ICommissionController.sol";
import "./interfaces/IShare.sol";

/**
 * @author https://github.com/alishaheen232
 * @title  ICO Presale Smart Contract
 * @notice This presale contract manages user funds for a project without intermediaries. Users can buy tokens using USDT.
 * The owner can pause the contract and withdraw funds. The contract includes functionality for sales agents and commission calculations.
 *
 * Requirements:
 *
 * - Token contract should be previously deployed, then deploy this presale contract by passing
 *   the Token contract address and USDT contract address in the constructor.
 * - Ensure the pair for both tokens is created in the Uniswap router before deployment.
 *   An error will occur during token purchases if the pair is not established.
 */

contract Presale is Ownable, Pausable {
    struct Memo {
        address user; // Address of the user involved in the transaction
        uint256 usdtAmount; // Amount of USDT involved in the transaction
        string memo; // Memo or description related to the transaction
        uint256 timestamp; // Timestamp of the transaction
    }

    IShare public immutable token;
    IShare public immutable usdt;
    IUniswapV2Router02 public immutable router;
    ICommissionController public immutable commissionController;

    uint256 public presaleRate; // Tokens per USDT rate
    uint256 public maxContribLimit;
    uint256 public constant hardCap = 1000000 * 10 ** 6; // Hard cap (1,000,000 USDT)

    Memo[] public offChainMemos; // Array to store deposit memos

    event BuyTokensOffChain(
        address indexed buyer,
        uint256 usdtAmount,
        uint256 tokenAmount
    );
    event BuyTokens(
        address indexed buyer,
        uint256 usdtAmount,
        uint256 tokenAmount
    );

    /**
     * @notice Constructor to initialize the presale contract.
     * @param _tokenAddress Address of the token contract.
     * @param _usdtAddress Address of the USDT contract.
     * @param _routerAddress Address of the Uniswap router contract.
     */
    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _routerAddress,
        address _commissionController
    ) Ownable(msg.sender) {
        token = IShare(_tokenAddress);
        usdt = IShare(_usdtAddress);
        router = IUniswapV2Router02(_routerAddress);
        commissionController = ICommissionController(_commissionController);

        maxContribLimit = token.marketAccount() / 200; // 0.5% of total market volume
    }

    /**
     * @notice Allows users to buy tokens during the presale.
     * @param usdtAmount Amount of USDT to spend.
     * @param salesAgent Address of the sales agent.
     */
    function buyTokens(
        uint256 usdtAmount,
        address salesAgent
    ) public whenNotPaused {
        require(
            usdt.balanceOf(address(this)) + usdtAmount <= hardCap,
            "Hard cap"
        );

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(usdt);

        uint256[] memory amountsOut = router.getAmountsOut(1 * 10 ** 18, path);
        presaleRate = amountsOut[1];
        uint256 tokenAmount = usdtAmount / presaleRate;

        require(tokenAmount <= maxContribLimit, "Max contribution");
        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Low token balance"
        );

        uint256 purcahsePercentage = (tokenAmount * 100) / maxContribLimit;

        commissionController.requestCommission(salesAgent, purcahsePercentage);

        usdt.transferFrom(msg.sender, address(this), usdtAmount);
        token.transfer(msg.sender, tokenAmount);

        emit BuyTokens(msg.sender, usdtAmount, tokenAmount);
    }

    /**
     * @notice Allows sales agents to buy tokens off-chain on behalf of users.
     * @param user Address of the user.
     * @param usdtAmount Amount of USDT to spend.
     */
    function buyTokensOffChain(
        address user,
        uint256 usdtAmount
    ) public whenNotPaused {
        require(salesAgents[msg.sender], "Not sales agent");

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(usdt);

        uint256[] memory amountsOut = router.getAmountsOut(1 * 10 ** 18, path);
        presaleRate = amountsOut[1];
        uint256 tokenAmount = usdtAmount / presaleRate;

        require(tokenAmount <= maxContribLimit, "Max contribution");
        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Low token balance"
        );

        commissionController.requestCommission(msg.sender, tokenAmount);

        token.transfer(user, tokenAmount);
        token.transfer(msg.sender, commissionAmount);

        offChainMemos.push(Memo(user, usdtAmount, memo, block.timestamp));

        emit BuyTokensOffChain(user, usdtAmount, tokenAmount);
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
     * @notice Allows the owner to transfer USDT from the contract to the owner's address.
     * @param usdtAmount Amount of USDT to transfer.
     */
    function transferUSDT(uint256 usdtAmount) external onlyOwner {
        require(usdtAmount > 0, "Zero amount");
        require(
            usdt.balanceOf(address(this)) >= usdtAmount,
            "Low USDT balance"
        );

        usdt.transfer(msg.sender, usdtAmount);
    }

    /**
     * @notice Allows the owner to set the status of a sales agent.
     * @param salesAgent Address of the sales agent.
     * @param status Boolean status of the sales agent.
     */
    function setSalesAgents(
        address salesAgent,
        bool status
    ) external onlyOwner {
        salesAgents[salesAgent] = status;
        emit SalesAgentUpdated(salesAgent, status);
    }

    /**
     * @notice Allows the owner to set the maximum contribution limit.
     */
    function setMaxContribLimit() external onlyOwner {
        maxContribLimit = ICommissionController.maxContribLimit();
    }

    /**
     * @notice Allows the owner to set the commission slabs.
     * @param _pp1 First purchase percentage slab.
     * @param _pp2 Second purchase percentage slab.
     * @param _pp3 Third purchase percentage slab.
     * @param _cp1 First commission percentage slab.
     * @param _cp2 Second commission percentage slab.
     * @param _cp3 Third commission percentage slab.
     */
    function setCommissionSlabs(
        uint256 _pp1,
        uint256 _pp2,
        uint256 _pp3,
        uint256 _cp1,
        uint256 _cp2,
        uint256 _cp3
    ) external onlyOwner {
        purchasePercentage = PurchasePercentage(_pp1, _pp2, _pp3);
        commissionPercentage = CommissionPercentage(_cp1, _cp2, _cp3);
    }

    /**
     * @notice Retrieves all Off-Chain memos.
     * @return Array of Off-Chain memos.
     */
    function getOffChainMemos() external view returns (Memo[] memory) {
        return offChainMemos;
    }
}
