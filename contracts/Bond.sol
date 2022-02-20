//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/ITreasury.sol";
import "./interface/IBondCalculator.sol";
import "./interface/ITAVCalculator.sol";

import "./library/FixedPoint.sol";
import "./library/SafeERC20.sol";

import "hardhat/console.sol";
import "./library/LowGasSafeMath.sol";
import "./interface/IStaking.sol";


contract Bond is Ownable {
    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;
    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 deposit,
        uint256 indexed payout,
        uint256 indexed expires,
        uint256 indexed priceInUSD
    );
    event BondRedeemed(
        address indexed recipient,
        uint256 payout,
        uint256 remaining
    );
    event BondPriceChanged(
        uint256 indexed priceInUSD,
        uint256 indexed internalPrice,
        uint256 indexed debtRatio
    );
    event ControlVariableAdjustment(
        uint256 initialBCV,
        uint256 newBCV,
        uint256 adjustment,
        bool addition
    );
    event InitTerms(Terms terms);
    event LogSetTerms(PARAMETER param, uint256 value);
    event LogSetAdjustment(Adjust adjust);
    event LogSetStaking(address indexed stakingContract);
    event LogTAVCalculator(address indexed tavCalculatorContract);
    event LogRecoverLostToken(address indexed tokenToRecover, uint256 amount);

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 minimumPrice; // vs principle value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
        uint256 minimumPayout; // minimum ORCL that needs to be bonded for
    }

    // Info for bond holder
    struct BondInfo {
        uint256 payout; // ORCL remaining to be paid
        uint256 pricePaid; // In DAI, for front end viewing
        uint32 lastTime; // Last interaction
        uint32 vesting; // Seconds left to vest
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 maxTarget; // BCV when adjustment finished
        uint256 minTarget; // BCV when adjustment finished
        uint32 buffer; // minimum length (in seconds) between adjustments
        uint32 lastTime; // time when last adjustment made
    }

    enum PARAMETER {
        VESTING,
        MAX_PAYOUT,
        FEE,
        DEBT,
        MINPRICE,
        MIN_PAYOUT
    }

    /* ======== STATE VARIABLES ======== */

    IERC20 public immutable ORCL; // token given as payment for bond
    IERC20 public principle; // token used to create bond
    ITreasury public immutable treasury; // mints ORCL when receives principle
    address public immutable DAO; // receives profit share from bond

    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    IBondCalculator public immutable bondCalculator; // calculates value of LP tokens

    IStaking public staking; // to auto-stake payout
    ITAVCalculator public tavCalculator; // to auto-stake payout
//    IStakingHelper public stakingHelper; // to stake and claim if no staking warmup
//    bool public useHelper;

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping(address => BondInfo) public bondInfo; // stores bond information for depositors

    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference time for debt decay

    /* ======== INITIALIZATION ======== */

    constructor(
        address _ORCL,
        address _principle,
        address _treasury,
        address _DAO,
        address _bondCalculator
    ) {
        require(_ORCL != address(0));
        ORCL = IERC20(_ORCL);
        require(_principle != address(0));
        principle = IERC20(_principle);
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);
        require(_DAO != address(0));
        DAO = _DAO;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = IBondCalculator(_bondCalculator);
        isLiquidityBond = (_bondCalculator != address(0));
        principle.approve(_treasury, 1e45);
    }

    /**
   *  @notice initializes bond parameters
   *  @param _controlVariable uint
   *  @param _vestingTerm uint32
   *  @param _minimumPrice uint
   *  @param _maxPayout uint
   *  @param _fee uint
   *  @param _maxDebt uint
   */
    function initializeBondTerms(
        uint256 _controlVariable,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _minPayout,
        uint256 _fee,
        uint256 _maxDebt,
        uint32 _vestingTerm
    ) external onlyOwner {
        require(terms.controlVariable == 0, 'Bonds must be initialized from 0');
        require(_controlVariable >= 0, 'Can lock adjustment');
        require(_maxPayout <= 10000, 'Payout cannot be above 1 percent');
        require(_vestingTerm >= 10, 'Vesting must be longer than 36 hours');
        require(_fee <= 10000, 'DAO fee cannot exceed payout');
        terms = Terms({
            controlVariable: _controlVariable,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt,
            vestingTerm: _vestingTerm,
            minimumPayout: _minPayout
        });
        lastDecay = uint32(block.timestamp);
        emit InitTerms(terms);
    }

    function setBondTerms(PARAMETER _parameter, uint256 _input)
    external
    onlyOwner
    {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 129600, 'Vesting must be longer than 36 hours');
            terms.vestingTerm = uint32(_input);
        } else if (_parameter == PARAMETER.MAX_PAYOUT) {
            // 1
            require(_input <= 1000, 'Payout cannot be above 1 percent');
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {
            // 2
            require(_input <= 10000, 'DAO fee cannot exceed payout');
            terms.fee = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 3
            terms.maxDebt = _input;
        } else if (_parameter == PARAMETER.MINPRICE) {
            // 4
            terms.minimumPrice = _input;
        } else if (_parameter == PARAMETER.MIN_PAYOUT) {
            // 5
            terms.minimumPayout = _input;
        }
        emit LogSetTerms(_parameter, _input);
    }

    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _maxTarget,
        uint256 _minTarget,
        uint32 _buffer
    ) external onlyOwner {
        require(
            _increment <= terms.controlVariable.mul(25) / 1000,
            'Increment too large'
        );
        require(_maxTarget >= 40, 'Next Adjustment could be locked');
        require(_minTarget <= 10, 'Next Adjustment could be locked');
        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            maxTarget: _maxTarget,
            minTarget: _minTarget,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
        emit LogSetAdjustment(adjustment);
    }

    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0), 'IA');
        staking = IStaking(_staking);
        ORCL.approve(address(staking), 1e45);
        emit LogSetStaking(_staking);
    }

    function setTAVCalculator(address _tavCalculator) external onlyOwner {
        require(_tavCalculator != address(0), 'IA');
        tavCalculator = ITAVCalculator(_tavCalculator);
        emit LogSetStaking(_tavCalculator);
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
   *  @param _amount uint
   *  @param _maxPrice uint
   *  @param _depositor address
   *  @return uint
   */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256) {
        require(_depositor != address(0), 'Invalid address');
        require(msg.sender == _depositor, 'LFNA');

        uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint256 nativePrice = bondPrice(); // bond price computed in 1e2 equivalent

        require(_maxPrice >= nativePrice, 'Slippage limit: more than max price'); // slippage protection

        uint256 value = treasury.valueOfToken(address(principle), _amount, true, false);
        uint256 payout = payoutFor(value); // payout to bonder is computed in 1e18

        require(totalDebt.add(value) <= terms.maxDebt, 'Max capacity reached');
        require(payout >= minPayout(), 'Bond too small'); // must be > 0.01 ORCL ( underflow protection )
        require(payout <= maxPayout(), 'Bond too large'); // size protection because there is no slippage

        // profits are calculated
        uint256 fee = payout.mul(terms.fee) / 100000;
        uint256 orclToMint = payout.add(fee);

        principle.safeTransferFrom(msg.sender, address(this), _amount);
        treasury.deposit(_amount, address(principle), orclToMint);

        if (fee != 0) {
            // fee is transferred to dao
            ORCL.safeTransfer(DAO, fee);
        }

        // total debt is increased
        totalDebt = totalDebt.add(value);

        // depositor info is stored
        bondInfo[_depositor] = BondInfo({
            payout: bondInfo[_depositor].payout.add(payout),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated(
            _amount,
            payout,
            block.timestamp.add(terms.vestingTerm),
            priceInUSD
        );
        emit BondPriceChanged(bondPriceInUSD(), bondPrice(), debtRatio());

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
   *  @notice redeem bond for user
   *  @param _recipient address
   *  @param _stake bool
   *  @return uint
   */
    function redeem(address _recipient, bool _stake) external returns (uint256) {
        require(msg.sender == _recipient, 'NA');
        BondInfo memory info = bondInfo[_recipient];
        // (seconds since last interaction / vesting term remaining)
        uint256 percentVested = percentVestedFor(_recipient);

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_recipient]; // delete user info
            emit BondRedeemed(_recipient, info.payout, 0); // emit bond data
            return stakeOrSend(_recipient, _stake, info.payout); // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = info.payout.mul(percentVested) / 10000;
            // store updated deposit info
            bondInfo[_recipient] = BondInfo({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub32(uint32(block.timestamp).sub32(info.lastTime)),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
            return stakeOrSend(_recipient, _stake, payout);
        }
    }

    /**
   *  @notice allow user to stake payout automatically
   *  @param _stake bool
   *  @param _amount uint
   *  @return uint
   */
    function stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal returns (uint256) {
        if (!_stake) {
            // if user does not want to stake
            ORCL.transfer(_recipient, _amount); // send payout
        } else {
            ORCL.approve(address(staking), _amount);
            staking.stake(_amount, _recipient);
        }
        return _amount;
    }

    /**
   *  @notice makes incremental adjustment to control variable
   */
    function adjust() internal {
        uint256 timeCanAdjust = adjustment.lastTime.add32(adjustment.buffer);
        if (adjustment.rate != 0 && block.timestamp >= timeCanAdjust) {
            uint256 initial = terms.controlVariable;
            uint256 bcv = initial;
            if (adjustment.add) {
                bcv = bcv.add(adjustment.rate);
                if (bcv >= adjustment.maxTarget) {
                    adjustment.add = !adjustment.add;
                }
            } else {
                bcv = bcv.sub(adjustment.rate);
                if (bcv <= adjustment.minTarget) {
                    adjustment.add = !adjustment.add;
                }
            }
            terms.controlVariable = bcv;
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment(
                initial,
                bcv,
                adjustment.rate,
                adjustment.add
            );
        }
    }

    /**
    *  @notice reduce total debt
    */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = uint32(block.timestamp);
    }

    /**
   *  @notice converts bond price to DAI value
   *  @return price_ uint
   */
    function bondPriceInUSD() public view returns (uint256 price_) {
        if (isLiquidityBond) {
            price_ = bondPrice().mul(bondCalculator.markdown(address(principle))) / 100;
        } else {
            price_ = bondPrice();
        }
    }

    /**
       *  @notice calculate current bond premium
       *  @return price_ uint
   */
    function bondPrice() public view returns (uint256 price_) {
        uint256 premium = terms.controlVariable.mul(debtRatio());
        uint256 TAV = tavCalculator.calculateTAV();
        if (premium < terms.minimumPrice) {
            premium = terms.minimumPrice;
        }

        price_ = (premium).add(TAV) / 1e7;
    }

    /**
   *  @notice determine maximum bond size
   *  @return uint
   */
    function maxPayout() public view returns (uint256) {
        return (ORCL.totalSupply().mul(terms.maxPayout) / 100000);
    }

    function minPayout() public view returns (uint256) {
        return terms.minimumPayout;
    }

    function vestingTerm() public view returns (uint256) {
        return terms.vestingTerm;
    }

    /**
   *  @notice calculate interest due for new bond
   *  @param _value uint
   *  @return uint
   */
    function payoutFor(uint256 _value) public returns (uint256) {
        return (FixedPoint.fraction(_value, bondPrice().mul(1e16)).decode112with18() / 1e9).mul(1e9);
    }

    /**
    *  @notice calculate current ratio of debt to ORCL supply
    *  @return debtRatio_ uint
    */
    function debtRatio() public view returns (uint256 debtRatio_) {
        uint256 supply = ORCL.totalSupply();
        debtRatio_ = FixedPoint.fraction(currentDebt().mul(1e9), supply).decode112with18() / 1e18;
    }

    /**
    *  @notice calculate debt factoring in decay
    *  @return uint
    */
    function currentDebt() public view returns (uint256) {
        return totalDebt.sub(debtDecay());
    }

    /**
    *  @notice amount to decay total debt by
    *  @return decay_ uint
    */
    function debtDecay() public view returns (uint256 decay_) {
        uint32 timeSinceLast = uint32(block.timestamp).sub32(lastDecay);
        decay_ = totalDebt.mul(timeSinceLast) / terms.vestingTerm;
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
   *  @notice calculate how far into vesting a depositor is
   *  @param _depositor address
   *  @return percentVested_ uint
   */
    function percentVestedFor(address _depositor)
    public
    view
    returns (uint256 percentVested_)
    {
        BondInfo memory bond = bondInfo[_depositor];
        uint256 secondsSinceLast = uint32(block.timestamp).sub32(bond.lastTime);
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = secondsSinceLast.mul(10000) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
   *  @notice calculate amount of ORCL available for claim by depositor
   *  @param _depositor address
   *  @return pendingPayout_ uint
   */
    function pendingPayoutFor(address _depositor)
    external
    view
    returns (uint256 pendingPayout_)
    {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = bondInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested) / 10000;
        }
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or ORCL) to the DAO
   *  @return bool
   */
    function recoverLostToken(IERC20 _token) external returns (bool) {
        require(_token != ORCL, 'NAT');
        require(_token != principle, 'NAP');
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(DAO, balance);
        emit LogRecoverLostToken(address(_token), balance);
        return true;
    }
}
