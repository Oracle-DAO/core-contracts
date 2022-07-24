// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

interface ICHRF {
    function burnFrom(address account_, uint256 amount_) external;

    function mint(address account_, uint256 amount_) external;

    function totalSupply() external view returns (uint256);
}

interface ITAVCalculator {
    function calculateTAV() external view returns (uint256 _TAV);
}

interface IBondCalculator {
    function valuation(address _LP, uint256 _amount)
    external
    view
    returns (uint256);

    function markdown(address _LP) external view returns (uint256);
}

interface ITreasuryHelper {
    function isReserveToken(address token_) external view returns (bool);

    function isReserveDepositor(address token_) external view returns (bool);

    function isReserveSpender(address token_) external view returns (bool);

    function isLiquidityToken(address token_) external view returns (bool);

    function isLiquidityDepositor(address token_) external view returns (bool);

    function isReserveManager(address token_) external view returns (bool);

    function isLiquidityManager(address token_) external view returns (bool);

    function isDebtor(address token_) external view returns (bool);

    function isRewardManager(address token_) external view returns (bool);
}

contract Treasury is Ownable {
    using FixedPoint for *;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 chrfMinted);
    event Withdrawal(address indexed token, uint256 amount, uint256 chrfBurned);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event ReservesManaged(address indexed token, uint256 amount);

    event ReservesUpdated(uint256 indexed totalReserves);

    address public immutable CHRF;
    address public sCHRF;
    address public tavCalculator;
    address public treasuryHelper;
    address public auditOwner;

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    mapping(address => uint256) public debtorBalance;

    uint256 private _totalReserves; // Risk-free value of all assets
    uint256 private _totalCHRFMinted; // total chrf minted
    uint256 private _totalDebt;

    constructor(address _CHRF, address _treasuryHelper) {
        require(_CHRF != address(0));
        CHRF = _CHRF;
        require(_treasuryHelper != address(0));
        treasuryHelper = _treasuryHelper;
    }

    function setStakedCHRF(address _sCHRF) external onlyOwner {
        require(_sCHRF != address(0));
        sCHRF = _sCHRF;
    }

    function setTAVCalculator(address _tavCalculator) external onlyOwner {
        tavCalculator = _tavCalculator;
    }

    function addLiquidityBond(address _token, address _liquidityBond) external onlyOwner {
        bondCalculator[_token] = _liquidityBond;
    }

    function removeLiquidityBond(address _liquidityBond) external onlyOwner {
        delete bondCalculator[_liquidityBond];
    }

    /**
    @notice allow approved address to deposit an asset for CHRF
        @param _amount uint
        @param _token address
        @param _chrfAmount uint
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _chrfAmount
    ) external {
        bool isReserveToken = ITreasuryHelper(treasuryHelper).isReserveToken(_token);
        bool isLiquidityToken = ITreasuryHelper(treasuryHelper).isLiquidityToken(_token);

        require(isReserveToken || isLiquidityToken, 'NA');

        if (isReserveToken) {
            require(ITreasuryHelper(treasuryHelper).isReserveDepositor(msg.sender), 'NAPPROVED');
        } else {
            require(ITreasuryHelper(treasuryHelper).isLiquidityDepositor(msg.sender), 'NAPPROVED');
        }
        uint256 value = valueOfToken(_token, _amount, isReserveToken, isLiquidityToken);
        _totalReserves = _totalReserves.add(value);
        _totalCHRFMinted = _totalCHRFMinted.add(_chrfAmount);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        ICHRF(CHRF).mint(msg.sender, _chrfAmount);

        emit ReservesUpdated(_totalReserves);
        emit Deposit(_token, _amount, _chrfAmount);
    }

    /**
    @notice allow approved address to burn CHRF for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        // Only reserves can be used for redemptions
        require(ITreasuryHelper(treasuryHelper).isReserveToken(_token), 'NA');
        require(ITreasuryHelper(treasuryHelper).isReserveSpender(msg.sender), 'NApproved');

        uint256 value = valueOfToken(_token, _amount, true, false);
        uint256 chrfToBurn = chrfEqValue(value);

        _totalCHRFMinted = _totalCHRFMinted.sub(chrfToBurn);
        _totalReserves = _totalReserves.sub(value);
        emit ReservesUpdated(_totalReserves);

        ICHRF(CHRF).burnFrom(msg.sender, chrfToBurn);
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdrawal(_token, _amount, chrfToBurn);
    }

    /**
    @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage(address _token, uint256 _amount) external {
        bool isLPToken = ITreasuryHelper(treasuryHelper).isLiquidityToken(_token);
        bool isReserveToken = ITreasuryHelper(treasuryHelper).isReserveToken(_token);
        if (isLPToken) {
            require(ITreasuryHelper(treasuryHelper).isLiquidityManager(msg.sender), 'NApproved');
        }

        if (isReserveToken) {
            require(ITreasuryHelper(treasuryHelper).isReserveManager(msg.sender), 'NApproved');
        }

        uint256 value = valueOfToken(_token, _amount, isReserveToken, isLPToken);
        _totalReserves = _totalReserves.sub(value);
        emit ReservesUpdated(_totalReserves);
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ReservesManaged(_token, _amount);
    }

    /**
    @notice returns CHRF valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken(address _token, uint256 _amount, bool isReserveToken, bool isLiquidToken) public
    view returns (uint256) {
        if (isReserveToken) {
            // convert amount to match CHRF decimals
            return _amount.mul(10**IERC20(CHRF).decimals()).div(10**IERC20(_token).decimals());
        } else if (isLiquidToken) {
            return IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
        return 0;
    }

    /**
    * @notice Returns stable coins amount valuation in CHRF
     * @param _amount uint
     */
    function chrfEqValue(uint256 _amount)
    public
    view
    returns (uint256 value_)
    {
        uint256 tav_= ITAVCalculator(tavCalculator).calculateTAV().mul(1e9);
        value_ = FixedPoint.fraction(_amount, tav_).decode112with18();
    }

    function totalReserves() external view returns(uint256) {
        return _totalReserves;
    }

    function totalCHRFMinted() external view returns(uint256) {
        return _totalCHRFMinted;
    }
}
