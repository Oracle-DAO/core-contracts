// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interface/IORCL.sol";
import "./interface/IAssetManager.sol";

import "./library/FixedPoint.sol";
import "./library/LowGasSafeMath.sol";
import "hardhat/console.sol";

contract TAVCalculator {
    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;
    IORCL public immutable ORCL;
    address[] assetManagers;

    constructor(address _orcl, address _treasury) {
        require(_orcl != address(0));
        ORCL = IORCL(_orcl);
        require(_treasury != address(0));
        assetManagers.push(_treasury);
    }

    function calculateTAV() external returns (uint256 _TAV) {
        uint256 orclTotalSupply = ORCL.totalSupply();
        uint256 totalReserve = 0;
        for (uint256 i = 0; i < assetManagers.length; i++) {
            totalReserve += IAssetManager(assetManagers[i]).totalReserves();
        }
        _TAV = calculateTAV(totalReserve, orclTotalSupply);
    }

    function calculateTAV(uint256 totalReserve, uint256 totalORCLSupply) internal returns(uint256) {
        return (FixedPoint.fraction(totalReserve, totalORCLSupply).decode112with18() / 1e16).mul(1e7);
    }
}
