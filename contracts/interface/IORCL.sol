// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IORCL {
    function burnFrom(address account_, uint256 amount_) external;

    function mint(address account_, uint256 amount_) external;

    function totalSupply() external view returns (uint256);
}
