// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./interface/IERC20.sol";

contract MIMFaucet {

    IERC20 public immutable mimContract;
    mapping(address => uint256) private _userMapping;

    constructor(address mimAddress) {
        require(mimAddress != address(0));
        mimContract = IERC20(mimAddress);
    }

    function faucet(address to_) external {
        require(to_ != address(0));
        require(_userMapping[to_] <= (1e18), "User has MIM");
        require(mimContract.balanceOf(address(this)) >= 1e20, "Insufficient MIM balance in faucet contract");
        mimContract.transfer(to_, 1e19);
    }
}
