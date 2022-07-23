// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _orfiMinted
    ) external;

    function valueOfToken(address _token, uint256 _amount, bool isReserveToken, bool isLiquidToken)
    external
    view
    returns (uint256 value_);

    function manage(address _token, uint256 _amount) external;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    function mul32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library FixedPoint {
    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
    {
        return uint256(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
    {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y)
    private
    pure
    returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (~d+1);
        d /= pow2;
        l /= pow2;
        l += h * ((~pow2+1) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

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
    mapping(uint8 => RewardCycle) public _rewardCycleMapping;
    mapping(address => uint8) private _userRecentRedeemMapping;
    mapping(address => mapping(uint8 => UserStakeInfo)) public _userStakeInfoToRewardCycleMapping;
    mapping(address => uint8) public _userActivityMapping;

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

    function completeRewardCycle(uint256 rewardAmount) external onlyOwner {
        require(rewardAmount > 0);
        RewardCycle memory rewardCycle = _rewardCycleMapping[currentRewardCycle];
        require(rewardCycle.startTimestamp < uint256(block.timestamp), "The cycle endTime should be GT startime");
        rewardCycle.endTimestamp = uint32(block.timestamp);
        rewardCycle.totalAllocatedRewards = rewardAmount;
        rewardCycle.totalStakedOrfiAmount = IERC20(_stakedOrfiAddress).totalSupply();
        _rewardCycleMapping[currentRewardCycle] = rewardCycle;
        emit RewardCycleCompleted(rewardAmount, rewardCycle.totalStakedOrfiAmount, currentRewardCycle);
        currentRewardCycle++;
        _totalRewardsAllocated += rewardAmount;
        _rewardCycleMapping[currentRewardCycle].startTimestamp = uint32(block.timestamp);
    }

    function stake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrfiBalance(to_, amount, true);
    }

    function unstake(address to_, uint256 amount) external onlyStakingContract {
        updateStakeOrfiBalance(to_, amount, false);
    }

    function redeemTotalRewardsForUser(address account_) external {
        require(account_ != address(0));
        for(uint8 i = _userRecentRedeemMapping[account_]+1; i<currentRewardCycle; i++){
            redeemRewardsForACycle(account_, i);
        }
    }

    function redeemRewardsForACycle(address account_, uint8 rewardCycle_) public {
        updateBalanceBasedOnPreviousCycle(account_);
        uint256 rewards = rewardsForACycle(account_, rewardCycle_);
        _userStakeInfoToRewardCycleMapping[account_][rewardCycle_].redeemed = true;
        _totalRewardsAllocated -= rewards;
        _userRecentRedeemMapping[account_] = rewardCycle_;
        ITreasury(_treasury).manage(_stableCoinAddress, rewards);
        IERC20(_stableCoinAddress).safeTransfer(account_, rewards);
        emit RedeemedRewards(account_, rewards, rewardCycle_);
    }

    function rewardsForACycle(address account_, uint8 rewardCycle_) public view returns(uint256) {
        require(account_ != address(0));
        require(rewardCycle_ < currentRewardCycle, "Invalid Reward Cycle");
        uint8 recentActivityCycle = _userActivityMapping[account_];

        UserStakeInfo memory userStakeInfo;
        if(rewardCycle_ > recentActivityCycle){
            userStakeInfo = _userStakeInfoToRewardCycleMapping[account_][recentActivityCycle];
            userStakeInfo.averageInvestedTime = 0;
        }
        else{
            userStakeInfo = _userStakeInfoToRewardCycleMapping[account_][rewardCycle_];
        }

        require(!userStakeInfo.redeemed, "User Has already Redeemed");

        RewardCycle memory rewardCycle = _rewardCycleMapping[rewardCycle_];
        uint32 cycleLength = rewardCycle.endTimestamp.sub32(rewardCycle.startTimestamp);
        uint256 investedTimeInCycle = averageTimeInCycle(cycleLength, userStakeInfo.averageInvestedTime);
        uint256 stakedOrfiPortion = calculateStakeOrfiPortion(userStakeInfo.stakedOrfiAmount, rewardCycle.totalStakedOrfiAmount);

        return calculateRewards(investedTimeInCycle, stakedOrfiPortion, rewardCycle.totalAllocatedRewards);
    }

    function updateStakeOrfiBalance(address to_, uint256 amount, bool isStake) internal returns(uint256){
        updateBalanceBasedOnPreviousCycle(to_);
        UserStakeInfo memory userStakeInfo = _userStakeInfoToRewardCycleMapping[to_][currentRewardCycle];
        _userActivityMapping[to_] = currentRewardCycle;
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

    function updateBalanceBasedOnPreviousCycle(address to_) internal {
        if(_userActivityMapping[to_] != currentRewardCycle) {
            for (uint8 i=_userActivityMapping[to_]+1; i<=currentRewardCycle; i++){
                UserStakeInfo memory userStakeInfo = _userStakeInfoToRewardCycleMapping[to_][i-1];
                UserStakeInfo memory newUserStakeInfo;
                newUserStakeInfo.averageInvestedTime = 0;
                newUserStakeInfo.rewardCycle = i;
                newUserStakeInfo.stakedOrfiAmount = userStakeInfo.stakedOrfiAmount;
                newUserStakeInfo.redeemed = false;
                _userStakeInfoToRewardCycleMapping[to_][i] = newUserStakeInfo;
            }
            _userActivityMapping[to_] = currentRewardCycle;
        }
    }

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

    function getTotalStakedOrfiOfUserForACycle(address account_, uint8 rewardCycle) external view returns(uint256 amount_) {
        amount_ = _userStakeInfoToRewardCycleMapping[account_][rewardCycle].stakedOrfiAmount;
    }

    function getTotalStakedOrfiForACycle(uint8 rewardCycle) external view returns(uint256 amount_) {
        amount_ = _rewardCycleMapping[rewardCycle].totalStakedOrfiAmount;
    }

}
