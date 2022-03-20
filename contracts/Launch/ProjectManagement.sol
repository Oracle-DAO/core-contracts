pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/LowGasSafeMath.sol";

import "../interface/IERC20.sol";
import "hardhat/console.sol";

contract ProjectManagement is Ownable{

    event MemberInfoAdded(address indexed account, uint256 amount, uint32 vestingPeriod);
    event TeamTokenRedeemed(address indexed account, uint256 payout, uint256 remaining);
    event MarketingTokenRedeemed(address indexed account, uint256 payout, uint256 remaining);

    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    struct MemberInfo{
        uint256 payout;
        uint32 vestingPeriod;
        uint32 startTime;
        uint32 lastRedeemTime;
        uint256 amountRedeemed;
    }

    mapping(address => bool) private _whitelisted;
    mapping(address => MemberInfo) private _tokenAllocation;
    mapping(address => bool) public marketingManager;

    uint256 private _totalAmountRedeemed;
    uint256 private _totalRemainingTeamTokens;
    uint256 private _totalRemainingMarketingTokens;

    address private _nttAddress;

    modifier onlyTeamMember() {
        require(_whitelisted[msg.sender], 'Not a team member');
        _;
    }

    constructor(address nttAddress_) {
        require(nttAddress_ != address(0));
        _totalRemainingTeamTokens = 1000000*(1e18);
        _totalRemainingMarketingTokens = 500000*(1e18);
        _nttAddress = nttAddress_;
    }

    function setMemberInfo(address account_, uint256 amount_, uint32 vestingPeriod_, bool forTeam) external onlyOwner {
        require(account_ != address(0));
        require(amount_ > 0);
        require(vestingPeriod_ > 0);
        if(forTeam){
            _totalRemainingTeamTokens -= amount_;
        }
        else{
            _totalRemainingMarketingTokens -= amount_;
        }
        require(_totalRemainingMarketingTokens >= 0, "Insufficient Tokens to allot");
        require(_totalRemainingTeamTokens >= 0, "Insufficient Tokens to allot");

        _whitelisted[account_] = true;
        _tokenAllocation[account_] = MemberInfo({
            payout: amount_,
            vestingPeriod: vestingPeriod_,
            startTime: uint32(block.timestamp),
            lastRedeemTime: uint32(block.timestamp),
            amountRedeemed: 0
        });

        emit MemberInfoAdded(account_, amount_, vestingPeriod_);
    }

    function redeem(address account_) external onlyTeamMember {
        require(account_ != address(0));
        uint32 percentVested = checkPercentVested(account_);
        MemberInfo memory memberInfo = _tokenAllocation[account_];
        if(percentVested >= 10000){
            _totalAmountRedeemed += memberInfo.payout;
            delete _tokenAllocation[account_];
            emit TeamTokenRedeemed(account_, memberInfo.payout, 0);
            send(account_, memberInfo.payout);
        }
        else{
            uint256 payout = memberInfo.payout.mul(percentVested) / 10000;
            _totalAmountRedeemed += payout;
            // store updated deposit info
            _tokenAllocation[account_] = MemberInfo({
                payout: memberInfo.payout.sub(payout),
                vestingPeriod: memberInfo.vestingPeriod.sub32(uint32(block.timestamp).sub32(memberInfo.lastRedeemTime)),
                lastRedeemTime: uint32(block.timestamp),
                startTime: memberInfo.startTime,
                amountRedeemed: payout.add(memberInfo.amountRedeemed)
            });

            emit TeamTokenRedeemed(account_, payout, _tokenAllocation[account_].payout);
            return send(account_, payout);
        }
    }

    function setMarketingManager(address account_) external onlyOwner {
        require(account_ != address(0));
        marketingManager[account_] = true;
    }

    function redeemTokenForMarketing(address account_, uint256 amount) external {
        require(account_ != address(0));
        require(amount > 0);
        require(marketingManager[msg.sender], "Not a marketing Manager");
        require(_totalRemainingMarketingTokens.sub(amount) >= 0, "Insufficient amount to allot");
        _totalRemainingMarketingTokens -= amount;
        emit MarketingTokenRedeemed(account_, amount, _totalRemainingMarketingTokens);
        send(account_, amount);
    }

    function blacklistMember(address account_) external onlyOwner {
        _whitelisted[account_] = false;
    }

    function send(address account_, uint256 amount) internal {
        IERC20(_nttAddress).transfer(account_, amount);
    }

    function checkPercentVested(address account_) public returns(uint32 percentVested_) {
        MemberInfo memory memberInfo = _tokenAllocation[account_];
        uint32 secondsSinceLast = uint32(block.timestamp).sub32(memberInfo.lastRedeemTime);
        if(secondsSinceLast >= memberInfo.vestingPeriod){
            percentVested_ = 10000;
        }
        else{
            percentVested_ = secondsSinceLast.mul32(10000) / memberInfo.vestingPeriod;
        }
    }

    function totalRemainingMarketingToken() external view returns(uint256) {
        return _totalRemainingMarketingTokens;
    }

    function totalRemainingTeamToken() external view returns(uint256) {
        return _totalRemainingTeamTokens;
    }

    function isWhitelisted(address account_) external view onlyOwner returns(bool) {
        return _whitelisted[account_];
    }

    function checkPayout(address account_) external view onlyOwner returns(uint256) {
        return _tokenAllocation[account_].payout;
    }

    function checkRemainingVestingPeriod(address account_) external view onlyTeamMember returns(uint32) {
        return _tokenAllocation[account_].vestingPeriod;
    }
}
