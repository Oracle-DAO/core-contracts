//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";
import "./library/LowGasSafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";
import "./interface/ITreasury.sol";

import "hardhat/console.sol";

contract RewardDistributor is Ownable {

    event RewardCycleCompleted(uint256 allocatedRewards, uint256 totalStakedOrcl, uint8 rewardCycle);
    event StakeBalanceUpdated(address indexed account, uint256 amount, uint256 averageTime);
    event UnstakeBalanceUpdated(address indexed account, uint256 amount, uint256 averageTime);
    event RedeemedRewards(address indexed account, uint256 amount, uint256 rewardCycle);

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
    address private _stableCoinAddress;
    address private _treasury;

    uint256 private _totalRewardsAllocated;

    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, 'OSC');
        _;
    }

    constructor(address stakingContract_, address stakedOrclAddress_) {
        require(stakingContract_ != address(0));
        require(stakedOrclAddress_ != address(0));
        currentRewardCycle = 1;
        _totalRewardsAllocated = 0;
        _rewardCycleMapping[currentRewardCycle].startTimestamp = uint32(block.timestamp);
        _stakingContract = stakingContract_;
        _stakedOrclAddress = stakedOrclAddress_;
    }

    function setStableCoinAddress(address stableCoinAddress_) external onlyOwner {
        _stableCoinAddress = stableCoinAddress_;
    }

    function setTreasuryAddress(address treasuryAddress_) external onlyOwner {
        _treasury = treasuryAddress_;
    }

    function completeRewardCycle(uint256 rewardAmount) external onlyOwner {
        require(rewardAmount > 0);
        RewardCycle memory rewardCycle = _rewardCycleMapping[currentRewardCycle];
        rewardCycle.endTimestamp = uint32(block.timestamp);
        rewardCycle.totalAllocatedRewards = rewardAmount;
        rewardCycle.totalStakedOrclAmount = IERC20(_stakedOrclAddress).totalSupply();
        _rewardCycleMapping[currentRewardCycle] = rewardCycle;
        emit RewardCycleCompleted(rewardAmount, rewardCycle.totalStakedOrclAmount, currentRewardCycle);
        currentRewardCycle++;
        _totalRewardsAllocated += rewardAmount;
    }

    function stake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrclBalance(to_, amount, true);
    }

    function unstake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrclBalance(to_, amount, false);
    }

    function redeemTotalRewards(address account_) external {
        require(account_ != address(0));
        for(uint8 i = _userRecentRedeemMapping[account_]+1; i<currentRewardCycle; i++){
            redeemRewardsForACycle(account_, i);
        }
    }

    function redeemRewardsForACycle(address account_, uint8 rewardCycle_) public {
        uint256 rewards = rewardsForACycle(account_, rewardCycle_);
        _userStakeInfoToRewardCycleMapping[account_][rewardCycle_].redeemed = true;
        _totalRewardsAllocated -= rewards;
        _userRecentRedeemMapping[account_] = rewardCycle_;
        ITreasury(_treasury).manage(_stableCoinAddress, rewards);
        emit RedeemedRewards(account_, rewards, rewardCycle_);
    }

    function rewardsForACycle(address account_, uint8 rewardCycle_) public returns(uint256) {
        require(account_ != address(0));
        require(rewardCycle_ < currentRewardCycle, "Invalid Reward Cycle");

        UserStakeInfo memory userStakeInfo = _userStakeInfoToRewardCycleMapping[account_][rewardCycle_];
        require(!userStakeInfo.redeemed, "User Has already Redeemed");
        require(userStakeInfo.stakedOrclAmount > 0, "Staked Amount is 0");
        RewardCycle memory rewardCycle = _rewardCycleMapping[rewardCycle_];
        uint32 cycleLength = rewardCycle.endTimestamp.sub32(rewardCycle.startTimestamp);

        uint256 investedTimeInCycle = averageTimeInCycle(cycleLength, userStakeInfo.averageInvestedTime);
        uint256 stakedOrclPortion = calculateStakeOrclPortion(userStakeInfo.stakedOrclAmount, rewardCycle.totalStakedOrclAmount);

        return calculateRewards(investedTimeInCycle, stakedOrclPortion, rewardCycle.totalAllocatedRewards);
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

            emit StakeBalanceUpdated(to_, amount, tAVG);
            return tAVG;
        }
        else {
            userStakeInfo.stakedOrclAmount = userStakeInfo.stakedOrclAmount.sub(amount);
            _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle] = userStakeInfo;
            if(userStakeInfo.stakedOrclAmount == 0){
                delete _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle];
            }
            emit UnstakeBalanceUpdated(to_, amount, userStakeInfo.averageInvestedTime);
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

    function averageTimeInCycle(uint256 cycleLength, uint256 averageInvestedTime) internal view returns(uint256) {
        return (FixedPoint.fraction(cycleLength.sub(averageInvestedTime), cycleLength).decode112with18() / 1e15).mul(1e15);
    }

    function calculateStakeOrclPortion(uint256 stakeOrclAmount, uint256 totalStakedOrclAmount) internal view returns(uint256) {
        return (FixedPoint.fraction(stakeOrclAmount, totalStakedOrclAmount).decode112with18() / 1e15).mul(1e15);
    }

    function calculateAverageTime(uint256 totalStakeTimeValue, uint256 totalStakedOrclAmount) internal view returns(uint256) {
        return (FixedPoint.fraction(totalStakeTimeValue, totalStakedOrclAmount).decode112with18() / 1e15).mul(1e15);
    }

    function calculateRewards(uint256 investedTime, uint256 stakedOrclPortion, uint256 totalRewards) internal returns(uint256) {
        return (investedTime.mul(stakedOrclPortion).mul(totalRewards)).div(1e36);
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
