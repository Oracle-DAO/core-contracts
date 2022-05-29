// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./interface/IERC20.sol";

contract OrfiFaucet {
    IERC20 public immutable orfiContract;
    mapping(address => uint256) private _userMapping;

    constructor(address orfiAddress) {
        require(orfiAddress != address(0));
        orfiContract = IERC20(orfiAddress);
    }

    function faucet(address to_) external {
        require(to_ != address(0));
        require(_userMapping[to_] < (1e19), "User has ORFI");
        require(orfiContract.balanceOf(address(this)) >= 1e20, "Insufficient ORFI balance in faucet contract");
        orfiContract.transfer(to_, 1e20);
    }
}
