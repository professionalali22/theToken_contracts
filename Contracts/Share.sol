// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./openzeppelin/contracts/access/Ownable2Step.sol";

contract MyToken is ERC20, ERC20Burnable, ERC20Permit, Ownable2Step {
    mapping (address => bool) public _iswhitelistAddress;    
    mapping (address => bool) public _exchangeAddress; 

    uint256 public _buyTax;  
    uint256 public _sellTax;
    uint256 public _transferTax;
    uint256 public _marketAccount;
    uint256 public _freezeAccount;
    uint256 public _maxSupply;

    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        ERC20Permit("MyToken")
        Ownable(initialOwner)
    {
        _maxSupply = 1000000000 * 10 ** decimals();
        uint256 _halfOfSupply = _maxSupply / 2;
        _iswhitelistAddress[initialOwner] = true;

        _mint(initialOwner, _halfOfSupply);
        _mint(address(this), _halfOfSupply);
        
        _marketAccount = _halfOfSupply;    
        _freezeAccount = _halfOfSupply;    
    }

    function _getTax(address from, address to) private view returns(uint256 taxFee) {
        // "to == address(0)" for burnnig, Tax must be 0 percent
        if (_iswhitelistAddress[from] || _iswhitelistAddress[to] || to == address(0)) {
            taxFee = 0;
        }else if(_exchangeAddress[from]){
            taxFee = _buyTax;
        }
        else if(_exchangeAddress[to]){
            taxFee = _sellTax;
        }
        else{
            taxFee = _transferTax;
        }
    }
 
    function _update(address from, address to, uint256 value) internal override  {
        uint256 taxFee = _getTax(from, to);
        uint256 fee = _calculateFee(value, taxFee);

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += (value - fee);
                _balances[owner()] += fee;
            }
        }

        emit Transfer(from, to, value);
    }

    function _calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return (amount * fee) /(10000);
    }

    function setWhiteListStatus(address account, bool status) public onlyOwner {
        _iswhitelistAddress[account] = status;
    }

    // @dev - Tax percentage must be in multiply of 100
    function setTaxPercentage(uint256 buyTax, uint256 sellTax, uint256 transferTax) public onlyOwner {
        require(buyTax <= 4900 || sellTax <= 4900 || transferTax <= 4900, "Tax percentage must be less than 49%");
        _buyTax = buyTax;  
        _sellTax = sellTax;
        _transferTax = transferTax;
    }

    function setExchangeAddress(address account, bool status) public onlyOwner {
        _exchangeAddress[account] = status;
    }

    // @dev - inflatePercentage must be in multiply of 100
    function inflateMarket(uint256 inflatePercentage) public onlyOwner {
        uint256 denominator = 10000;
        require(inflatePercentage <= denominator, "{inflatePercentage} must be less than or equal to {denominator}");
        
        uint256 inflateAmount = (_freezeAccount * inflatePercentage) / denominator;

        unchecked{
            _freezeAccount -= inflateAmount;
            _marketAccount += inflateAmount;
            _balances[address(this)] -= inflateAmount;
            _balances[owner()] += inflateAmount;
        }
    }
}
