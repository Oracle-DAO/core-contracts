// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interface/IORFI.sol";
import "../interface/IAssetManager.sol";

import "../library/FixedPoint.sol";
import "../library/LowGasSafeMath.sol";

contract TAVCalculator {
    event AssetManagerAdded(address indexed assetManagerAddress);

    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;
    IORFI public immutable ORFI;
    address[] assetManagers;
    address public _owner;
    mapping(address => bool) blacklistedAddress;

    constructor(address _orfi, address _treasury) {
        _owner = msg.sender;
        require(_orfi != address(0));
        ORFI = IORFI(_orfi);
        require(_treasury != address(0));
        assetManagers.push(_treasury);
    }

    function blacklistAddress(address account_) external {
        require(msg.sender == _owner, 'Invalid Caller');
        require(account_ != address(0));
        blacklistedAddress[account_] = true;
    }

    function whitelistAddress(address account_) external {
        require(msg.sender == _owner, 'Invalid Caller');
        require(account_ != address(0));
        delete blacklistedAddress[account_];
    }

    function calculateTAV() external view returns (uint256 _TAV) {
        uint256 orfiTotalSupply = ORFI.totalSupply();
        uint256 totalReserve = 0;
        for (uint256 i = 0; i < assetManagers.length; i++) {
            if(!blacklistedAddress[address(assetManagers[i])]){
                totalReserve += IAssetManager(assetManagers[i]).totalReserves();
            }
        }
        _TAV = calculateTAV(totalReserve, orfiTotalSupply);
    }

    function calculateTAV(uint256 totalReserve, uint256 totalORFISupply) internal pure returns(uint256) {
        return (FixedPoint.fraction(totalReserve, totalORFISupply).decode112with18() / 1e9);
    }

    function addAssetManager(address assetManager_) external {
        require(msg.sender == _owner, 'Invalid Caller');
        require(assetManager_ != address(0));
        emit AssetManagerAdded(assetManager_);
        assetManagers.push(assetManager_);
    }
}
