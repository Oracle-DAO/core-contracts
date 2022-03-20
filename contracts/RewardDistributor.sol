//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";
import "./library/LowGasSafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";

import "hardhat/console.sol";

contract RewardDistributor is Ownable {

    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    struct RewardCycle {
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint256 totalStakedOrclAmount;
        uint256 totalAllocatedRewards;
    }

    struct UserStakeInfo {
        uint256 stakedOrclAmount;
        uint32 averageInvestedTime;
        uint8 rewardCycle;
        bool redeemed;
    }

    uint8 public currentRewardCycle;
    mapping(uint8 => RewardCycle) private _rewardCycleMapping;
    mapping(address => uint8) private _userRecentRedeemMapping;
    mapping(address => mapping(uint8 => UserStakeInfo)) public _userStakeInfoToRewardCycleMapping;

    address private _stakingContract;
    address private _stakedOrclAddress;

    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, 'OSC');
        _;
    }

    constructor(address stakingContract_, address stakedOrclAddress_) {
        currentRewardCycle = 1;
        _rewardCycleMapping[currentRewardCycle].startTimestamp = uint32(block.timestamp);
        _stakingContract = stakingContract_;
        _stakedOrclAddress = stakedOrclAddress_;
    }

    function completeRewardCycle(uint256 rewardAmount) external onlyOwner {
        RewardCycle memory rewardCycle = _rewardCycleMapping[currentRewardCycle];
        rewardCycle.endTimestamp = uint32(block.timestamp);
        rewardCycle.totalAllocatedRewards = rewardAmount;
        rewardCycle.totalStakedOrclAmount = IERC20(_stakedOrclAddress).totalSupply();
        _rewardCycleMapping[currentRewardCycle] = rewardCycle;
        currentRewardCycle++;
    }

    function stake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrclBalance(to_, amount, true);
    }

    function unstake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrclBalance(to_, amount, false);
    }

    function updateStakeOrclBalance(address to_, uint256 amount, bool isStake) internal returns(uint256){
        UserStakeInfo memory userStakeInfo = _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle];
        if(isStake) {
            uint256 tAVG = calculateAverageTime
            (
                userStakeInfo.averageInvestedTime,
                _rewardCycleMapping[currentRewardCycle].startTimestamp,
                userStakeInfo.stakedOrclAmount,
                amount
            );
            userStakeInfo.averageInvestedTime = uint32(tAVG.div(1e18));
            userStakeInfo.stakedOrclAmount = userStakeInfo.stakedOrclAmount.add(amount);
            userStakeInfo.rewardCycle = currentRewardCycle;
            _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle] = userStakeInfo;
            return tAVG;
        }
        else {
            userStakeInfo.stakedOrclAmount = userStakeInfo.stakedOrclAmount.sub(amount);
            _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle] = userStakeInfo;
            if(userStakeInfo.stakedOrclAmount == 0){
                delete _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle];
            }
            return userStakeInfo.averageInvestedTime;
        }
    }

    function calculateAverageTime(uint32 tAVG, uint32 rewardCycleStartTime, uint256 stakedOrclAmount, uint256 amount) internal view returns(uint256){
        uint256 stakeTimeValue = tAVG.mul(stakedOrclAmount);
        uint256 stakingTime = block.timestamp.sub(rewardCycleStartTime);
        uint256 currentStakeTimeValue = amount.mul(stakingTime);
        uint256 totalStakeTimeValue = stakeTimeValue.add(currentStakeTimeValue);
        return calculateAverageTime(totalStakeTimeValue, stakedOrclAmount.add(amount));
    }

    function calculateAverageTime(uint256 totalStakeTimeValue, uint256 totalStakedOrclAmount) internal view returns(uint256) {
        return (FixedPoint.fraction(totalStakeTimeValue, totalStakedOrclAmount).decode112with18() / 1e15).mul(1e15);
    }


    function stakingContract() external view returns(address) {
        return _stakingContract;
    }

    function stakedOrclAddress() external view returns(address) {
        return _stakedOrclAddress;
    }

    function getTotalRewardsForCycle(uint8 rewardCycleId) external view returns(uint256) {
        return _rewardCycleMapping[rewardCycleId].totalAllocatedRewards;
    }

    function getRewardCycleTimeWindow(uint8 rewardCycleId) external view returns(uint32 startTime_, uint32 endTime_) {
        startTime_ = _rewardCycleMapping[rewardCycleId].startTimestamp;
        endTime_ = _rewardCycleMapping[rewardCycleId].endTimestamp;
    }
}
