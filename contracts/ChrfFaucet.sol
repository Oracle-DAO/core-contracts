// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./interface/IERC20.sol";

contract ChrfFaucet {
    IERC20 public immutable chrfContract;
    mapping(address => uint256) private _userMapping;

    constructor(address chrfAddress) {
        require(chrfAddress != address(0));
        chrfContract = IERC20(chrfAddress);
    }

    function faucet(address to_) external {
        require(to_ != address(0));
        require(_userMapping[to_] < (1e19), "User has CHRF");
        require(chrfContract.balanceOf(address(this)) >= 1e20, "Insufficient CHRF balance in faucet contract");
        chrfContract.transfer(to_, 1e20);
    }
}
