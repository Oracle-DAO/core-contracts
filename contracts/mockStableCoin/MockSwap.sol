pragma solidity ^0.8.0;

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface ISwapPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract MockSwap {

    address public routerAddress;

    constructor () {

    }

    function setRouter(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0));
        routerAddress = _routerAddress;
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB, address userAddress) external
    returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        return IDEXRouter(routerAddress).addLiquidity(tokenA, tokenB, amountA, amountB, userAddress, 1e18);
    }

    function swapExactTokens(address tokenA, address tokenB, uint256 amountAIn, address to) external {
        IDEXRouter(routerAddress).swapExactTokensForTokens(amountAIn, 0, tokenA, tokenB, to, 1e18);
    }

    function swapExactTokensForTokensSupportingFee(address tokenA, address tokenB, uint256 amountAIn, address to) external {
        IDEXRouter(routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountAIn, 0, tokenA, tokenB, to, 1e18);
    }
}
