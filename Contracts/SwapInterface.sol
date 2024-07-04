// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IShare.sol";

contract ExchangeInterface is Ownable{
    IUniswapV2Router02 public router;
    IShare public usdt;
    IShare public token;

    constructor(address _router, address _usdt, address _token) Ownable(msg.sender){
        router = IUniswapV2Router02(_router);
        usdt = IShare(_usdt);
        token = IShare(_token);
    }   

    function addLiquidity(address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount) public{
        require(IERC20(_tokenA).approve(address(router), _tokenAAmount), "_tokenA approval issue");
        require(IERC20(_tokenB).approve(address(router), _tokenBAmount), "_tokenB approval issue");
        router.addLiquidity(address(_tokenA), address(_tokenB), _tokenAAmount, _tokenBAmount, 0, 0, msg.sender, block.timestamp + 5);
    }

    function swapExactTokensForToken(address _tokenA, address _tokenB, uint256 _tokenAAmount) private  {
        address[] memory path = new address[](2);
        path[0] = address(_tokenA);
        path[1] = address(_tokenB);
        require(IERC20(_tokenA).approve(address(router), _tokenAAmount), "_tokenA approval issue");
        router.swapExactTokensForTokens(
            _tokenAAmount,
            0, 
            path,
            address(this),
            block.timestamp + 5
        );
    }

    function swapTokensForExactTokens(address _tokenA, address _tokenB, uint256 _tokenBAmount, uint256 _tokenAAmountMax) private {
        address[] memory path = new address[](2);
        path[0] = address(_tokenA);
        path[1] = address(_tokenB);
        require(IERC20(_tokenA).approve(address(router), _tokenAAmountMax), "_tokenA approval issue");
        router.swapTokensForExactTokens(
            _tokenBAmount,
            _tokenAAmountMax,
            path,
            address(this),
            block.timestamp + 5
        );
    }

    /**
     * @notice Allows the owner to withdraw tokens from the contract.
     * @param _token Address of the token contract to withdraw.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(IERC20(_token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(_token).transfer(msg.sender, amount);
    
    }

}