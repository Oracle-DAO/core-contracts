// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interface/ISwapPair.sol";
import "../interface/IERC20.sol";

contract LpAsset is Ownable {
    event LpDeposited(address indexed account, uint256 amount, uint256 price);
    event LpManaged(address indexed account, uint256 amount);
    ISwapPair public lpAddress;
    IERC20 public principal;
    using SafeMath for uint256;

    mapping(address => bool) isManager;

    uint256 public totalLpTokens;

    constructor (address lpAddress_, address principal_) {
        require(lpAddress_ != address(0));
        require(principal_ != address(0));
        lpAddress = ISwapPair(lpAddress_);
        principal = IERC20(principal_);
        isManager[msg.sender] = true;
    }

    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0));
        isManager[_manager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        delete isManager[_manager];
    }

    function deposit(uint256 amount_) external {
        require(amount_ > 0, "amount cannot be 0");
        require(lpAddress.balanceOf(msg.sender) >= amount_, "User doesn't have entered amount");
        totalLpTokens += amount_;
        lpAddress.approve(address(this), amount_);
        lpAddress.transferFrom(msg.sender, address(this), amount_);
    }

    function totalReserves() external view returns(uint256 reserves_) {
        (uint112 _reserve0, uint112 _reserve1,) = lpAddress.getReserves();
        (uint112 reserve0, ) = lpAddress.token0() ==  address(principal) ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        reserves_ =  uint256(reserve0).mul(2);
    }

    function totalInvestedAmount() external pure returns(uint256 totalInvestmentAmount_) {
        totalInvestmentAmount_ = 0;
    }

    function manage(uint256 amount_) external {
        require(isManager[msg.sender], "Caller is not manager");
        require(amount_ > 0, "Amount should be GT 0");
        require(lpAddress.balanceOf(address(this)) >= amount_, "Insufficient Balance in contract");
        totalLpTokens = totalLpTokens.sub(amount_);
        emit LpManaged(msg.sender, amount_);
        lpAddress.transfer(msg.sender, amount_);
    }

    function convertInto18DecimalsEquivalent(uint256 _amount) internal view returns(uint256) {
        return (_amount.mul(1e18)).div(10 ** principal.decimals());
    }
}
