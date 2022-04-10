// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interface/IORFI.sol";
import "../interface/IAssetManager.sol";

import "../library/FixedPoint.sol";
import "../library/LowGasSafeMath.sol";

contract TAVCalculator {
    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;
    IORFI public immutable ORFI;
    address[] assetManagers;

    constructor(address _orfi, address _treasury) {
        require(_orfi != address(0));
        ORFI = IORFI(_orfi);
        require(_treasury != address(0));
        assetManagers.push(_treasury);
    }

    // TODO Add events and documentation

    function calculateTAV() external view returns (uint256 _TAV) {
        uint256 orfiTotalSupply = ORFI.totalSupply();
        uint256 totalReserve = 0;
        for (uint256 i = 0; i < assetManagers.length; i++) {
            totalReserve += IAssetManager(assetManagers[i]).totalReserves();
        }
        _TAV = calculateTAV(totalReserve, orfiTotalSupply);
    }

    function calculateTAV(uint256 totalReserve, uint256 totalORFISupply) internal pure returns(uint256) {
        return (FixedPoint.fraction(totalReserve, totalORFISupply).decode112with18() / 1e9);
    }
}
