// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interface/IAssetManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LpManager is Ownable {
    event LpAssetAdded(address indexed lpAssetAddress);
    IAssetManager[] lpAssetAddress;

    function totalReserves() external view returns(uint256) {
        uint256 amount = 0;
        for(uint8 i=0; i< lpAssetAddress.length; i++){
            amount += lpAssetAddress[i].totalReserves();
        }
        return amount;
    }

    function totalInvestedAmounts() external view returns(uint256) {
        uint256 amount = 0;
        for(uint8 i=0; i< lpAssetAddress.length; i++){
            amount += lpAssetAddress[i].totalInvestedAmount();
        }
        return amount;
    }

    function addLpAssetManager(address lpAssetContractAddress_) external onlyOwner {
        require(lpAssetContractAddress_ != address(0));
        emit LpAssetAdded(lpAssetContractAddress_);
        lpAssetAddress.push(IAssetManager(lpAssetContractAddress_));
    }
}
