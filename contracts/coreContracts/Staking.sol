// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IRewardDistributor {
  function stake(address to_, uint256 amount) external;

  function unstake(address to_, uint256 amount) external;
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

contract Staking is Ownable {
  /* ========== DEPENDENCIES ========== */

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== EVENTS ========== */

  event WarmupSet(uint256 warmup);
  event ChrfStaked(address indexed account, uint256 amount);
  event ChrfUnstaked(address indexed account, uint256 amount);

  /* ========== DATA STRUCTURES ========== */

  struct Epoch {
    uint256 length; // in seconds
    uint256 number; // since inception
    uint256 end; // timestamp
    uint256 distribute; // amount
  }

  struct Claim {
    uint256 deposit; // if forfeiting
    uint256 expiry; // end of warmup period
    bool lock; // prevents malicious delays for claim
  }

  /* ========== STATE VARIABLES ========== */

  IERC20 public immutable CHRF;
  IERC20 public immutable sCHRF;
  IRewardDistributor public rewardDistributor;

  mapping(address => Claim) public warmupInfo;
  uint256 public warmupPeriod;
  uint256 private amountInWarmup;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _chrf,
    address _schrf
  ) {
    require(_chrf != address(0), "Zero address: CHRF");
    CHRF = IERC20(_chrf);
    require(_schrf != address(0), "Zero address: sCHRF");
    sCHRF = IERC20(_schrf);
  }

  function setRewardDistributor(address rewardDistributor_) external onlyOwner {
    rewardDistributor = IRewardDistributor(rewardDistributor_);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice stake CHRF to enter warmup
     * @param _to address
     * @param _amount uint
     * @return uint
     */
  function stake(
    address _to,
    uint256 _amount
  ) external returns (uint256) {
    CHRF.safeTransferFrom(msg.sender, address(this), _amount);
    if (warmupPeriod == 0) {
      _send(_to, _amount);
      rewardDistributor.stake(_to, _amount);
      emit ChrfStaked(_to, _amount);
      return _amount;
    } else {
        Claim memory info = warmupInfo[_to];
        if (!info.lock) {
          require(_to == msg.sender, "External deposits for account are locked");
        }

        warmupInfo[_to] = Claim({
          deposit: info.deposit.add(_amount),
          expiry: block.timestamp.add(warmupPeriod),
          lock: info.lock
        });

        amountInWarmup = amountInWarmup.add(_amount);
        return _amount;
    }
  }

  /**
   * @notice retrieve stake from warmup
     * @param _to address
     * @return uint
     */
  function claim(address _to) external returns (uint256) {
    Claim memory info = warmupInfo[_to];

    if (!info.lock) {
      require(_to == msg.sender, "External claims for account are locked");
    }

    if (block.timestamp >= info.expiry && info.expiry != 0) {
      delete warmupInfo[_to];

      amountInWarmup = amountInWarmup.sub(info.deposit);
      emit ChrfStaked(_to, info.deposit);
      return _send(_to, info.deposit);
    }
    return 0;
  }

  /**
   * @notice forfeit stake and retrieve CHRF
   * @return uint
  */
  function forfeit() external returns (uint256) {
    Claim memory info = warmupInfo[msg.sender];
    delete warmupInfo[msg.sender];
    amountInWarmup = amountInWarmup.sub(info.deposit);
    CHRF.safeTransfer(msg.sender, info.deposit);
    return info.deposit;
  }

  /**
   * @notice prevent new deposits or claims from ext. address (protection from malicious activity)
     */
  function toggleLock() external {
    warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
  }

  /**
   * @notice redeem sOHM for OHMs
     * @param _to address
     * @param _amount uint
     * @return amount_ uint
     */
  function unstake(
    address _to,
    uint256 _amount
  ) external returns (uint256 amount_) {
    sCHRF.burn(msg.sender, _amount);
    require(_amount <= CHRF.balanceOf(address(this)), "Insufficient CHRF balance in contract");
    CHRF.safeTransfer(_to, _amount);
    rewardDistributor.unstake(_to, _amount);
    emit ChrfUnstaked(_to, _amount);
    return _amount;
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
   * @notice send staker their amount as sCHRF
     * @param _to address
     * @param _amount uint
     */
  function _send(
    address _to,
    uint256 _amount
  ) internal returns (uint256) {
      sCHRF.mint(_to, _amount); // send as sCHRF (equal unit as CHRF)
      return _amount;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * @notice total supply in warmup
     */
  function supplyInWarmup() external view returns (uint256) {
    return amountInWarmup;
  }

  /**
   * @notice CHRF balance present in contract
   */
  function contractCHRFBalance() external view returns (uint256) {
    return CHRF.balanceOf(address(this));
  }

  /* ========== MANAGERIAL FUNCTIONS ========== */

  /**
   * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
  function setWarmupLength(uint256 _warmupPeriod) external onlyOwner {
    warmupPeriod = _warmupPeriod;
    emit WarmupSet(_warmupPeriod);
  }

  /**
   * @notice get reward distributor address
   */
  function getRewardDistributorAddress() external view returns(address) {
    return address(rewardDistributor);
  }
}
