// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITreasuryHelper {
    function isReserveToken(address token_) external view returns (bool);

    function isReserveDepositor(address token_) external view returns (bool);

    function isReserveSpender(address token_) external view returns (bool);

    function isLiquidityToken(address token_) external view returns (bool);

    function isLiquidityDepositor(address token_) external view returns (bool);

    function isReserveManager(address token_) external view returns (bool);

    function isLiquidityManager(address token_) external view returns (bool);

    function isDebtor(address token_) external view returns (bool);

    function isRewardManager(address token_) external view returns (bool);
}
