pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract NTT is  Context, Ownable, ERC20 {

    event Redeemed(address indexed account, uint256 amount);
    event RedeemedStatus(bool redeemableStatus);

    using SafeMath for uint256;

    bool public redeemable;
    address private orclAddress;
    uint256 private totalOrclRedeemed;

    // TODO Need to make transfer, approve onlyowner/onlyProjectManagement and balanceOf only(msg.sender)

    constructor() ERC20('Non Transferable Oracle Token', 'nORCL') {
        redeemable = false;
    }

    function setOrclAddress(address orclAddress_) external onlyOwner{
        orclAddress = orclAddress_;
    }

    function mint(address account, uint256 amount) external onlyOwner{
        _mint(account, amount);
    }

    function burnFrom(address account_, uint256 amount_) external virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal virtual {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(amount_);
        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function redeemORCL(uint256 amount_) external {
        require(redeemable, "Redeem is not allowed");
        _burn(msg.sender, amount_);

        totalOrclRedeemed += amount_;

        IERC20(orclAddress).transfer(msg.sender, amount_);
        emit Redeemed(msg.sender, amount_);
    }

    function toggleRedeemFlag() external onlyOwner {
        redeemable = !redeemable;
        emit RedeemedStatus(redeemable);
    }
}
