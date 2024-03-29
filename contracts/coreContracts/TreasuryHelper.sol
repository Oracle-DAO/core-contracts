// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/IBondCalculator.sol";
import "../library/SafeERC20.sol";
import "../interface/ITreasury.sol";

contract TreasuryHelper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable ORFI;
    ITreasury public treasury;

    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(
        MANAGING indexed managing,
        address activated,
        bool result
    );
    event ReservesUpdated(uint256 indexed totalReserves);
    event ReservesAudited(uint256 indexed totalReserves);

    enum MANAGING {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        DEBTOR,
        REWARDMANAGER,
        SORFI
    }

    uint256 public immutable blocksNeededForQueue;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping(address => bool) public isReserveToken;
    mapping(address => uint256) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveDepositor;
    mapping(address => uint256) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveSpender;
    mapping(address => uint256) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;
    mapping(address => uint256) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;
    mapping(address => uint256) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveManager;
    mapping(address => uint256) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityManager;
    mapping(address => uint256) public LiquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isDebtor;
    mapping(address => uint256) public debtorQueue; // Delays changes to mapping.

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    mapping(address => uint256) public rewardManagerQueue; // Delays changes to mapping.

    address public sORFI;
    uint256 public sORFIQueue;

    constructor(
        address _ORFI,
        address _MIM,
        uint256 _blocksNeededForQueue
    ) {
        require(_ORFI != address(0));
        ORFI = _ORFI;

        require(_MIM != address(0));
        reserveTokens.push(_MIM);

        isReserveToken[_MIM] = true;
        blocksNeededForQueue = _blocksNeededForQueue;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0));
        treasury = ITreasury(_treasuryAddress);
    }

    /**
    @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue(MANAGING _managing, address _address)
    external
    onlyOwner
    returns (bool)
    {
        require(_address != address(0));
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            reserveDepositorQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            reserveSpenderQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            reserveTokenQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            ReserveManagerQueue[_address] = block.number.add(
                blocksNeededForQueue.mul(2)
            );
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            LiquidityDepositorQueue[_address] = block.number.add(
                blocksNeededForQueue
            );
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            LiquidityTokenQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            LiquidityManagerQueue[_address] = block.number.add(
                blocksNeededForQueue.mul(2)
            );
        } else if (_managing == MANAGING.DEBTOR) {
            // 7
            debtorQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            rewardManagerQueue[_address] = block.number.add(blocksNeededForQueue);
        } else if (_managing == MANAGING.SORFI) {
            // 9
            sORFIQueue = block.number.add(blocksNeededForQueue);
        } else return false;

        emit ChangeQueued(_managing, _address);
        return true;
    }

    /**
    @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle(
        MANAGING _managing,
        address _address,
        address _calculator
    ) external onlyOwner returns (bool) {
        require(_address != address(0));
        bool result;
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            if (requirements(reserveDepositorQueue, isReserveDepositor, _address)) {
                reserveDepositorQueue[_address] = 0;
                if (!listContains(reserveDepositors, _address)) {
                    reserveDepositors.push(_address);
                }
            }
            result = !isReserveDepositor[_address];
            isReserveDepositor[_address] = result;
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
                reserveSpenderQueue[_address] = 0;
                if (!listContains(reserveSpenders, _address)) {
                    reserveSpenders.push(_address);
                }
            }
            result = !isReserveSpender[_address];
            isReserveSpender[_address] = result;
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            if (requirements(reserveTokenQueue, isReserveToken, _address)) {
                reserveTokenQueue[_address] = 0;
                if (!listContains(reserveTokens, _address)) {
                    reserveTokens.push(_address);
                }
            }
            result = !isReserveToken[_address];
            isReserveToken[_address] = result;
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            if (requirements(ReserveManagerQueue, isReserveManager, _address)) {
                reserveManagers.push(_address);
                ReserveManagerQueue[_address] = 0;
                if (!listContains(reserveManagers, _address)) {
                    reserveManagers.push(_address);
                }
            }
            result = !isReserveManager[_address];
            isReserveManager[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            if (
                requirements(LiquidityDepositorQueue, isLiquidityDepositor, _address)
            ) {
                liquidityDepositors.push(_address);
                LiquidityDepositorQueue[_address] = 0;
                if (!listContains(liquidityDepositors, _address)) {
                    liquidityDepositors.push(_address);
                }
            }
            result = !isLiquidityDepositor[_address];
            isLiquidityDepositor[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
                LiquidityTokenQueue[_address] = 0;
                if (!listContains(liquidityTokens, _address)) {
                    liquidityTokens.push(_address);
                }
            }
            result = !isLiquidityToken[_address];
            isLiquidityToken[_address] = result;
            bondCalculator[_address] = _calculator;
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            if (requirements(LiquidityManagerQueue, isLiquidityManager, _address)) {
                LiquidityManagerQueue[_address] = 0;
                if (!listContains(liquidityManagers, _address)) {
                    liquidityManagers.push(_address);
                }
            }
            result = !isLiquidityManager[_address];
            isLiquidityManager[_address] = result;
        } else if (_managing == MANAGING.DEBTOR) {
            // 7
            if (requirements(debtorQueue, isDebtor, _address)) {
                debtorQueue[_address] = 0;
                if (!listContains(debtors, _address)) {
                    debtors.push(_address);
                }
            }
            result = !isDebtor[_address];
            isDebtor[_address] = result;
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            if (requirements(rewardManagerQueue, isRewardManager, _address)) {
                rewardManagerQueue[_address] = 0;
                if (!listContains(rewardManagers, _address)) {
                    rewardManagers.push(_address);
                }
            }
            result = !isRewardManager[_address];
            isRewardManager[_address] = result;
        } else if (_managing == MANAGING.SORFI) {
            // 9
            sORFIQueue = 0;
            sORFI = _address;
            result = true;
        } else return false;

        emit ChangeActivated(_managing, _address, result);
        return true;
    }

    /**
    @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool
     */
    function requirements(
        mapping(address => uint256) storage queue_,
        mapping(address => bool) storage status_,
        address _address
    ) internal view returns (bool) {
        if (!status_[_address]) {
            require(queue_[_address] != 0, 'Must queue');
            require(queue_[_address] <= block.number, 'Queue not expired');
            return true;
        }
        return false;
    }

    /**
    @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token)
    internal
    view
    returns (bool)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken(address _token, uint256 _amount) external view returns (uint256 value_) {
        if (isReserveToken[_token]) {
            // convert amount to match OHM decimals
            value_ = _amount.mul(10**IERC20(ORFI).decimals()).div(10**IERC20(_token).decimals());
        } else if (isLiquidityToken[_token]) {
            value_ = IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
        else{
            // this will never happen!!
            value_= 0;
        }
    }
}
