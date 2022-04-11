// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interface/ITreasuryHelper.sol";
import "../interface/IBondCalculator.sol";
import "../interface/ITAVCalculator.sol";
import "../interface/IORFI.sol";
import "../interface/IERC20.sol";

import "../library/SafeERC20.sol";
import "../library/FixedPoint.sol";

contract Treasury is Ownable {
    using FixedPoint for *;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 orfiMinted);
    event Withdrawal(address indexed token, uint256 amount, uint256 orfiBurned);
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

    address public immutable ORFI;
    address public sORFI;
    address public tavCalculator;
    address public treasuryHelper;
    address public auditOwner;

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    mapping(address => uint256) public debtorBalance;

    uint256 private _totalReserves; // Risk-free value of all assets
    uint256 private _totalORFIMinted; // total orfi minted
    uint256 private _totalDebt;

    constructor(address _ORFI, address _treasuryHelper) {
        require(_ORFI != address(0));
        ORFI = _ORFI;
        require(_treasuryHelper != address(0));
        treasuryHelper = _treasuryHelper;
    }

    function setStakedORFI(address _sORFI) external onlyOwner {
        require(_sORFI != address(0));
        sORFI = _sORFI;
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
    @notice allow approved address to deposit an asset for ORFI
        @param _amount uint
        @param _token address
        @param _orfiAmount uint
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _orfiAmount
    ) external {
        bool isReserveToken = ITreasuryHelper(treasuryHelper).isReserveToken(_token);
        bool isLiquidityToken = ITreasuryHelper(treasuryHelper).isLiquidityToken(_token);

        require(isReserveToken || isLiquidityToken, 'NA');

        if (isReserveToken) {
            require(ITreasuryHelper(treasuryHelper).isReserveDepositor(msg.sender), 'NAPPROVED');
        } else {
            require(ITreasuryHelper(treasuryHelper).isLiquidityDepositor(msg.sender), 'NAPPROVED');
        }

        _totalReserves = _totalReserves.add(_amount);
        _totalORFIMinted = _totalORFIMinted.add(_orfiAmount);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IORFI(ORFI).mint(msg.sender, _orfiAmount);

        emit ReservesUpdated(_totalReserves);
        emit Deposit(_token, _amount, _orfiAmount);
    }

    /**
    @notice allow approved address to burn ORFI for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        // Only reserves can be used for redemptions
        require(ITreasuryHelper(treasuryHelper).isReserveToken(_token), 'NA');
        require(ITreasuryHelper(treasuryHelper).isReserveSpender(msg.sender), 'NApproved');

        uint256 orfiToBurn = orfiEqValue(valueOfToken(_token, _amount, true, false));

        _totalORFIMinted = _totalORFIMinted.sub(orfiToBurn);
        _totalReserves = _totalReserves.sub(_amount);
        emit ReservesUpdated(_totalReserves);

        IORFI(ORFI).burnFrom(msg.sender, orfiToBurn);
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdrawal(_token, _amount, orfiToBurn);
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

        _totalReserves = _totalReserves.sub(_amount);
        emit ReservesUpdated(_totalReserves);
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ReservesManaged(_token, _amount);
    }

    /**
    @notice returns ORFI valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken(address _token, uint256 _amount, bool isReserveToken, bool isLiquidToken) public
    view returns (uint256) {
        if (isReserveToken) {
            // convert amount to match ORFI decimals
            return _amount.mul(10**IERC20(ORFI).decimals()).div(10**IERC20(_token).decimals());
        } else if (isLiquidToken) {
            return IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
        return 0;
    }

    function orfiEqValue(uint256 _amount)
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

    function totalORFIMinted() external view returns(uint256) {
        return _totalORFIMinted;
    }
}
