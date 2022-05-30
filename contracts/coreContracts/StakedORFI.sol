// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakedORFI is Context, ERC20{
    using SafeMath for uint256;

    address public stakingContract;
    address public initializer;

    event LogStakingContractUpdated(address stakingContract);

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, 'Not a staking contract');
        _;
    }

    constructor() ERC20('Staked Oracle', 'sORFI') {
        initializer = msg.sender;
    }

    function initialize(address stakingContract_) external returns (bool) {
        require(msg.sender == initializer, 'NA');
        require(stakingContract_ != address(0), 'IA');
        stakingContract = stakingContract_;

        emit LogStakingContractUpdated(stakingContract_);

        initializer = address(0);
        return true;
    }

    function mint(address to, uint256 amount) external onlyStakingContract {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyStakingContract {
        _burn(to, amount);
    }

    /**
   *  @notice Only stakingContract can transfer sORFI
   *  @param to address
   *  @param amount uint256
   */
    function transfer(address to, uint256 amount) public override onlyStakingContract returns (bool) {
         address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
   *  @notice Only stakingContract can transfer sORFI
   *  @param from address
   *  @param to address
   *  @param amount uint256
   */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyStakingContract returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

}
