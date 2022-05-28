// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interface/IAssetManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LpBondManager is Ownable {
    event LpBondAdded(address indexed lpBondAddress);
    IAssetManager[] lpBondAddress;

    function totalReserves() external view returns(uint256) {
        uint256 amount = 0;
        for(uint8 i=0; i< lpBondAddress.length; i++){
            amount += lpBondAddress[i].totalReserves();
        }
        return amount;
    }

    function totalInvestedAmounts() external view returns(uint256) {
        uint256 amount = 0;
        for(uint8 i=0; i< lpBondAddress.length; i++){
            amount += lpBondAddress[i].totalInvestedAmount();
        }
        return amount;
    }

    function addLpAssetManager(address bondContractAddress_) external {
        require(bondContractAddress_ != address(0));
        emit LpBondAdded(bondContractAddress_);
        lpBondAddress.push(IAssetManager(bondContractAddress_));
    }
}
