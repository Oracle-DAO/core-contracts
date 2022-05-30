// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

interface IRewardDistributor {
    function stake(address to_, uint256 amount) external;

    function unstake(address to_, uint256 amount) external;
}
