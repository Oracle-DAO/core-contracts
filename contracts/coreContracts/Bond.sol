// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IStaking {
    function stake(address _recipient, uint256 _amount) external returns (uint256);
}

interface ITAVCalculator {
    function calculateTAV() external view returns (uint256 _TAV);
}

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _chrfMinted
    ) external;

    function valueOfToken(address _token, uint256 _amount, bool isReserveToken, bool isLiquidToken)
    external
    view
    returns (uint256 value_);

    function manage(address _token, uint256 _amount) external;
}

interface IBondCalculator {
    function valuation(address _LP, uint256 _amount)
    external
    view
    returns (uint256);

    function markdown(address _LP) external view returns (uint256);
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
        uint256 bondingRewardFee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
        uint256 minimumPayout; // minimum CHRF that needs to be bonded for
    }

    // Info for bond holder
    struct BondInfo {
        uint256 payout; // CHRF remaining to be paid
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
        MIN_PAYOUT,
        BONDING_FEE
    }

    /* ======== STATE VARIABLES ======== */

    IERC20 public immutable CHRF; // token given as payment for bond
    IERC20 public principle; // token used to create bond
    ITreasury public immutable treasury; // mints CHRF when receives principle
    address public immutable DAO; // receives profit share from bond

    IStaking public staking; // to auto-stake payout
    ITAVCalculator public tavCalculator; // to calculate TAV

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping(address => BondInfo) public bondInfo; // stores bond information for depositors

    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference time for debt decay
    uint256 public bondingReward;
    uint256 public floorPriceValue;

    /* ======== INITIALIZATION ======== */

    constructor(
        address _CHRF,
        address _principle,
        address _treasury,
        address _DAO
    ) {
        require(_CHRF != address(0));
        CHRF = IERC20(_CHRF);
        require(_principle != address(0));
        principle = IERC20(_principle);
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);
        require(_DAO != address(0));
        DAO = _DAO;

        principle.approve(_treasury, 1e45);
    }

    /**
   *  @notice initializes bond parameters
   *  @param _controlVariable uint
   *  @param _minimumPrice uint
   *  @param _maxPayout uint
   *  @param _minPayout uint
   *  @param _fee uint
   *  @param _bondingRewardFee uint
   *  @param _maxDebt uint
   *  @param _vestingTerm uint32
   */
    function initializeBondTerms(
        uint256 _controlVariable,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _minPayout,
        uint256 _fee,
        uint256 _bondingRewardFee,
        uint256 _maxDebt,
        uint32 _vestingTerm
    ) external onlyOwner {
        require(terms.controlVariable == 0, 'Bonds must be initialized from 0');
        require(_controlVariable >= 0, 'Can lock adjustment');
        require(_maxPayout <= 10000, 'Payout cannot be above 10 percent');
        require(_vestingTerm >= 10, 'Vesting must be longer than 36 hours');
        require(_fee <= 10000, 'DAO fee cannot exceed payout');
        require(_bondingRewardFee <= 10000, 'Bonding reward fee cannot be above 10%');
        terms = Terms({
            controlVariable: _controlVariable,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            bondingRewardFee: _bondingRewardFee,
            maxDebt: _maxDebt,
            vestingTerm: _vestingTerm,
            minimumPayout: _minPayout
        });
        lastDecay = uint32(block.timestamp);
        emit InitTerms(terms);
    }

    function setBondTerms(PARAMETER _parameter, uint256 _input) external onlyOwner {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 86400, 'Vesting must be longer than 36 hours');
            terms.vestingTerm = uint32(_input);
        } else if (_parameter == PARAMETER.MAX_PAYOUT) {
            // 1
            require(_input <= 10000, 'Payout cannot be above 10 percent');
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {
            // 2
            require(_input <= 10000, 'DAO fee cannot exceed 10%');
            require(_input >= 2000, 'DAO fee cannot go below 2%');
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
        } else if (_parameter == PARAMETER.BONDING_FEE) {
            // 5
            terms.bondingRewardFee = _input;
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
            _increment <= terms.controlVariable.mul(500) / 1000,
            'Increment too large'
        );
        require(_maxTarget >= 1000, 'Next Adjustment could be locked');
        require(_minTarget <= 1000, 'Next Adjustment could be locked');
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
        emit LogSetStaking(_staking);
        CHRF.approve(address(staking), 1e45);
    }

    function setFloorPriceValue(uint256 _value) external onlyOwner {
        require(_value != 0);
        floorPriceValue = _value;
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
   *  @return uint
   */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice
    ) external returns (uint256) {
        decayDebt();

        // convert stablecoin decimals to 18 equivalent
        uint256 amount = convertInto18DecimalsEquivalent(_amount);

        uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
        bondingReward = bondingReward.add(calculateBondingReward()); // calculate bonding rewards

        require(_maxPrice >= priceInUSD, 'Slippage limit: more than max price'); // slippage protection

        uint256 payout = payoutFor(amount); // payout to bonder is computed in 1e18

        require(totalDebt.add(amount) <= terms.maxDebt, 'Max capacity reached');
        require(payout >= minPayout(), 'Bond too small'); // must be > 0.01 CHRF ( underflow protection )
        require(payout <= maxPayout(), 'Bond too large'); // size protection because there is no slippage

        // profits are calculated
        uint256 fee = payout.mul(terms.fee) / 100000;
        uint256 chrfToMint = payout.add(fee);

        // total debt is increased
        totalDebt = totalDebt.add(_amount);

        // depositor info is stored
        bondInfo[msg.sender] = BondInfo({
            payout: bondInfo[msg.sender].payout.add(payout),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        principle.safeTransferFrom(msg.sender, address(this), _amount);
        treasury.deposit(_amount, address(principle), chrfToMint);

        if (fee != 0) {
            // fee is transferred to dao
            CHRF.safeTransfer(DAO, fee);
        }

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
   */
    function redeem(address _recipient, bool _stake) external {
        require(msg.sender == _recipient, 'NA');
        BondInfo memory info = bondInfo[_recipient];
        // (seconds since last interaction / vesting term remaining)
        uint256 percentVested = percentVestedFor(_recipient);

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_recipient]; // delete user info
            emit BondRedeemed(_recipient, info.payout, 0); // emit bond data
            stakeOrSend(_recipient, _stake, info.payout); // pay user everything due
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
            stakeOrSend(_recipient, _stake, payout);
        }
    }

    /**
   *  @notice allow user to stake payout automatically
   *  @param _stake bool
   *  @param _amount uint
   */
    function stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal {
        if (!_stake) {
            // if user does not want to stake
            CHRF.safeTransfer(_recipient, _amount); // send payout
        } else {
            staking.stake(_recipient, _amount);
        }
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
   *  @notice converts bond price to StableCoin value
   *  @return price_ uint
   */
    function bondPriceInUSD() public view returns (uint256 price_) {
        price_ = bondPrice();
    }

    /**
       *  @notice calculate current bond premium
       *  @return price_ uint
   */
    function bondPrice() public view returns (uint256 price_) {
        uint256 TAV = tavCalculator.calculateTAV(); // 1e9 decimal equivalent
        uint256 premium = TAV.mul(terms.fee).div(1e5) + terms.controlVariable.mul(debtRatio());
        price_ = (premium).add(TAV > floorPriceValue ? TAV : floorPriceValue) / 1e7; // price calculates in 1e3 equivalent
    }

    /**
       *  @notice calculate bonding reward from premium
       *  @return bondingReward_ uint
   */
    function calculateBondingReward() public view returns (uint256 bondingReward_) {
        uint256 TAV = tavCalculator.calculateTAV(); // 1e9 decimal equivalent
        uint256 premium = TAV.mul(terms.fee).div(1e5) + terms.controlVariable.mul(debtRatio());
        bondingReward_ = premium.mul(terms.bondingRewardFee).div(1e12); // bondingReward_ calculated in 1e3 equivalent
    }

    /**
   *  @notice determine maximum bond size
   *  @return uint
   */
    function maxPayout() public view returns (uint256) {
        return (CHRF.totalSupply().mul(terms.maxPayout) / 100000);
    }

    function minPayout() internal view returns (uint256) {
        return terms.minimumPayout;
    }

    /**
   *  @notice calculate interest due for new bond
   *  @param _value uint
   *  @return uint
   */
    function payoutFor(uint256 _value) public view returns (uint256) {
        return (FixedPoint.fraction(_value, bondPrice().mul(1e16)).decode112with18() / 1e9).mul(1e9);
    }

    /**
    *  @notice calculate current ratio of debt to CHRF supply in 1e9 equivalent
    *  @return debtRatio_ uint
    */
    function debtRatio() public view returns (uint256 debtRatio_) {
        uint256 supply = CHRF.totalSupply();
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
   *  @notice calculate amount of CHRF available for claim by depositor
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

    function convertInto18DecimalsEquivalent(uint256 _amount) internal view returns(uint256) {
        return (_amount.mul(1e18)).div(10 ** principle.decimals());
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or CHRF) to the DAO
   *  @return bool
   */
    function recoverLostToken(address _token) external returns (bool) {
        require(_token != address(CHRF), 'NAT');
        require(_token != address(principle), 'NAP');
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(DAO, balance);
        emit LogRecoverLostToken(_token, balance);
        return true;
    }
}
