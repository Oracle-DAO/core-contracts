// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

interface ICHRF {
    function burnFrom(address account_, uint256 amount_) external;

    function mint(address account_, uint256 amount_) external;

    function totalSupply() external view returns (uint256);
}
