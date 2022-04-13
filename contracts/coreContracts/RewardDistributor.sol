// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../library/FixedPoint.sol";
import "../library/LowGasSafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/SafeERC20.sol";
import "../interface/ITreasury.sol";


contract RewardDistributor is Ownable {

    event RewardCycleCompleted(uint256 allocatedRewards, uint256 totalStakedOrfi, uint8 rewardCycle);
    event StakeBalanceUpdated(address indexed account, uint256 amount, uint256 averageTime);
    event UnstakeBalanceUpdated(address indexed account, uint256 amount, uint256 averageTime);
    event RedeemedRewards(address indexed account, uint256 amount, uint256 rewardCycle);

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    struct RewardCycle {
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint256 totalStakedOrfiAmount;
        uint256 totalAllocatedRewards;
    }

    struct UserStakeInfo {
        uint256 stakedOrfiAmount;
        uint32 averageInvestedTime;
        uint8 rewardCycle;
        bool redeemed;
    }

    uint8 public currentRewardCycle;
    mapping(uint8 => RewardCycle) private _rewardCycleMapping;
    mapping(address => uint8) private _userRecentRedeemMapping;
    mapping(address => mapping(uint8 => UserStakeInfo)) public _userStakeInfoToRewardCycleMapping;

    address private _stakingContract;
    address private _stakedOrfiAddress;
    address private _stableCoinAddress;
    address private _treasury;

    uint256 private _totalRewardsAllocated;

    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, 'OSC');
        _;
    }

    constructor(address stakingContract_, address stakedOrfiAddress_) {
        require(stakingContract_ != address(0));
        require(stakedOrfiAddress_ != address(0));
        currentRewardCycle = 1;
        _totalRewardsAllocated = 0;
        _rewardCycleMapping[currentRewardCycle].startTimestamp = uint32(block.timestamp);
        _stakingContract = stakingContract_;
        _stakedOrfiAddress = stakedOrfiAddress_;
    }

    function setStableCoinAddress(address stableCoinAddress_) external onlyOwner {
        require(stableCoinAddress_ != address(0));
        _stableCoinAddress = stableCoinAddress_;
    }

    function setTreasuryAddress(address treasuryAddress_) external onlyOwner {
        require(treasuryAddress_ != address(0));
        _treasury = treasuryAddress_;
    }

    /**
   *  @notice This complete the reward cycle and alot a reward amount for the corresponding cycle
   *  @param rewardAmount uint256
   */
    function completeRewardCycle(uint256 rewardAmount) external onlyOwner {
        require(rewardAmount > 0);
        RewardCycle memory rewardCycle = _rewardCycleMapping[currentRewardCycle];
        rewardCycle.endTimestamp = uint32(block.timestamp);
        rewardCycle.totalAllocatedRewards = rewardAmount;
        rewardCycle.totalStakedOrfiAmount = IERC20(_stakedOrfiAddress).totalSupply();
        _rewardCycleMapping[currentRewardCycle] = rewardCycle;
        emit RewardCycleCompleted(rewardAmount, rewardCycle.totalStakedOrfiAmount, currentRewardCycle);
        currentRewardCycle++;
        _totalRewardsAllocated += rewardAmount;
        _rewardCycleMapping[currentRewardCycle].startTimestamp = uint32(block.timestamp);
    }

    /**
   *  @notice This function is triggered when user stake ORFI. The sOrfi and average time value for the respective cycle get updated
   *  @param to_ address
   *  @param amount uint256
   */
    function stake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrfiBalance(to_, amount, true);
    }

    /**
   *  @notice This function is triggered when user unstake sORFI. The sOrfi value for the respective cycle get updated
   *  @param to_ address
   *  @param amount uint256
   */
    function unstake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrfiBalance(to_, amount, false);
    }

    /**
   *  @notice User can redeem rewards for all the cycle
   *  @param account_ address
   */
    function redeemTotalRewardsForUser(address account_) external {
        require(account_ != address(0));
        for(uint8 i = _userRecentRedeemMapping[account_]+1; i<currentRewardCycle; i++){
            redeemRewardsForACycle(account_, i);
        }
    }

    /**
   *  @notice User can redeem reward for a cycle
   *  @param account_ address
   *  @param rewardCycle_ uint8
   */
    function redeemRewardsForACycle(address account_, uint8 rewardCycle_) public {
        uint256 rewards = rewardsForACycle(account_, rewardCycle_);
        _userStakeInfoToRewardCycleMapping[account_][rewardCycle_].redeemed = true;
        _totalRewardsAllocated -= rewards;
        _userRecentRedeemMapping[account_] = rewardCycle_;
        ITreasury(_treasury).manage(_stableCoinAddress, rewards);
        IERC20(_stableCoinAddress).safeTransfer(account_, rewards);
        emit RedeemedRewards(account_, rewards, rewardCycle_);
    }

    /**
   *  @notice Check user reward for a cycle
   *  @param account_ address
   *  @param rewardCycle_ uint8
   *  @return uint256
   */
    function rewardsForACycle(address account_, uint8 rewardCycle_) public view returns(uint256) {
        require(account_ != address(0));
        require(rewardCycle_ < currentRewardCycle, "Invalid Reward Cycle");

        UserStakeInfo memory userStakeInfo = _userStakeInfoToRewardCycleMapping[account_][rewardCycle_];
        require(!userStakeInfo.redeemed, "User Has already Redeemed");
        require(userStakeInfo.stakedOrfiAmount > 0, "Staked Amount is 0");
        RewardCycle memory rewardCycle = _rewardCycleMapping[rewardCycle_];
        uint32 cycleLength = rewardCycle.endTimestamp.sub32(rewardCycle.startTimestamp);

        uint256 investedTimeInCycle = averageTimeInCycle(cycleLength, userStakeInfo.averageInvestedTime);
        uint256 stakedOrfiPortion = calculateStakeOrfiPortion(userStakeInfo.stakedOrfiAmount, rewardCycle.totalStakedOrfiAmount);

        return calculateRewards(investedTimeInCycle, stakedOrfiPortion, rewardCycle.totalAllocatedRewards);
    }

    function updateStakeOrfiBalance(address to_, uint256 amount, bool isStake) internal returns(uint256){
        UserStakeInfo memory userStakeInfo = _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle];
        if(isStake) {
            uint256 tAVG = calculateAverageTime
            (
                userStakeInfo.averageInvestedTime,
                _rewardCycleMapping[currentRewardCycle].startTimestamp,
                userStakeInfo.stakedOrfiAmount,
                amount
            );
            userStakeInfo.averageInvestedTime = uint32(tAVG.div(1e18));
            userStakeInfo.stakedOrfiAmount = userStakeInfo.stakedOrfiAmount.add(amount);
            userStakeInfo.rewardCycle = currentRewardCycle;
            _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle] = userStakeInfo;

            emit StakeBalanceUpdated(to_, amount, tAVG);
            return tAVG;
        }
        else {
            userStakeInfo.stakedOrfiAmount = userStakeInfo.stakedOrfiAmount.sub(amount);
            _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle] = userStakeInfo;
            if(userStakeInfo.stakedOrfiAmount == 0){
                delete _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle];
            }
            emit UnstakeBalanceUpdated(to_, amount, userStakeInfo.averageInvestedTime);
            return userStakeInfo.averageInvestedTime;
        }
    }

    /**
   *  @notice Calculate invested average time of a user
   *  @param tAVG uint32
   *  @param rewardCycleStartTime uint32
   *  @param stakedOrfiAmount uint256
   *  @param amount uint256
   *  @return uint256
   */
    function calculateAverageTime(uint32 tAVG, uint32 rewardCycleStartTime, uint256 stakedOrfiAmount, uint256 amount) internal view returns(uint256){
        uint256 stakeTimeValue = tAVG.mul(stakedOrfiAmount);
        uint256 stakingTime = block.timestamp.sub(rewardCycleStartTime);
        uint256 currentStakeTimeValue = amount.mul(stakingTime);
        uint256 totalStakeTimeValue = stakeTimeValue.add(currentStakeTimeValue);
        return calculateAverageTime(totalStakeTimeValue, stakedOrfiAmount.add(amount));
    }

    function averageTimeInCycle(uint256 cycleLength, uint256 averageInvestedTime) internal pure returns(uint256) {
        return (FixedPoint.fraction(cycleLength.sub(averageInvestedTime), cycleLength).decode112with18() / 1e15).mul(1e15);
    }

    function calculateStakeOrfiPortion(uint256 stakeOrfiAmount, uint256 totalStakedOrfiAmount) internal pure returns(uint256) {
        return (FixedPoint.fraction(stakeOrfiAmount, totalStakedOrfiAmount).decode112with18() / 1e15).mul(1e15);
    }

    function calculateAverageTime(uint256 totalStakeTimeValue, uint256 totalStakedOrfiAmount) internal pure returns(uint256) {
        return (FixedPoint.fraction(totalStakeTimeValue, totalStakedOrfiAmount).decode112with18() / 1e15).mul(1e15);
    }

    function calculateRewards(uint256 investedTime, uint256 stakedOrfiPortion, uint256 totalRewards) internal pure returns(uint256) {
        return (investedTime.mul(stakedOrfiPortion).mul(totalRewards)).div(1e36);
    }

    function stakingContract() external view returns(address) {
        return _stakingContract;
    }

    function stakedOrfiAddress() external view returns(address) {
        return _stakedOrfiAddress;
    }

    function getTotalRewardsForCycle(uint8 rewardCycleId) external view returns(uint256) {
        return _rewardCycleMapping[rewardCycleId].totalAllocatedRewards;
    }

    function getRewardCycleTimeWindow(uint8 rewardCycleId) external view returns(uint32 startTime_, uint32 endTime_) {
        startTime_ = _rewardCycleMapping[rewardCycleId].startTimestamp;
        endTime_ = _rewardCycleMapping[rewardCycleId].endTimestamp;
    }

    function getTotalRewardsForUser(address account_) external view returns(uint256) {
        require(account_ != address(0));
        uint256 totalRewards_ = 0;
        for(uint8 i = _userRecentRedeemMapping[account_]+1; i<currentRewardCycle; i++){
            totalRewards_ += rewardsForACycle(account_, i);
        }
        return totalRewards_;
    }
}
