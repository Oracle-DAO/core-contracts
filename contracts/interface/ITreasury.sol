// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITreasury {
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _orclMinted
  ) external;

  function valueOfToken(address _token, uint256 _amount, bool isReserveToken, bool isLiquidToken)
    external
    view
    returns (uint256 value_);
}
