// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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
        uint256 stableCoinReserves = convertInto18DecimalsEquivalent(uint256(reserve0));
        reserves_ =  stableCoinReserves.mul(2);
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
