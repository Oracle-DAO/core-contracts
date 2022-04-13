// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

interface IStaking {
  function stake(address _recipient, uint256 _amount) external returns (uint256);
}
