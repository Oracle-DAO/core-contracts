// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../interface/IORFI.sol";
import "../interface/IAssetManager.sol";

import "../library/FixedPoint.sol";
import "../library/LowGasSafeMath.sol";

contract TAVCalculator {

    event AssetManagerAdded(address indexed account);

    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;
    IORFI public immutable ORFI;
    address[] assetManagers;
    address public _owner;

    constructor(address _orfi, address _treasury) {
        _owner = msg.sender;
        require(_orfi != address(0));
        ORFI = IORFI(_orfi);
        require(_treasury != address(0));
        assetManagers.push(_treasury);
    }

    /**
    * @notice Calculate total asset value of ORFI. It returns uint in 1e9 equivalent
     * @return _TAV uint
     */
    function calculateTAV() external view returns (uint256 _TAV) {
        uint256 orfiTotalSupply = ORFI.totalSupply();
        uint256 totalReserve = 0;
        for (uint256 i = 0; i < assetManagers.length; i++) {
            totalReserve += IAssetManager(assetManagers[i]).totalReserves();
        }
        _TAV = calculateTAV(totalReserve, orfiTotalSupply);
    }

    /**
    * @notice Calculate fraction of total reserve to that of total ORFI supply
     * @return uint
     */
    function calculateTAV(uint256 totalReserve, uint256 totalORFISupply) internal pure returns(uint256) {
        return (FixedPoint.fraction(totalReserve, totalORFISupply).decode112with18() / 1e9);
    }

    /**
    * @notice Add asset manager contracts TAV calculation
     * @param assetManager_ address
     */
    function addAssetManager(address assetManager_) external {
        require(msg.sender == _owner, 'Invalid Caller');
        require(assetManager_ != address(0));
        assetManagers.push(assetManager_);
        emit AssetManagerAdded(assetManager_);
    }
}
