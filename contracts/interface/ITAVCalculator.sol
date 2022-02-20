// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITAVCalculator {
    function calculateTAV() external view returns (uint256 _TAV);
}
