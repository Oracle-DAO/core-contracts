// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

interface IAssetManager {
    function totalReserves() external view returns(uint256);

    function totalInvestedAmount() external view returns(uint256);
}
