// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NTT is  Context, Ownable, ERC20 {

    event Redeemed(address indexed account, uint256 amount);
    event RedeemedStatus(bool redeemableStatus);

    using SafeMath for uint256;

    bool public redeemable;
    address private orfiAddress;
    uint256 private totalOrfiRedeemed;
    mapping(address => bool) public transferApprovedAddress;
    uint256 public totalNTTSupply;
    uint256 public totalNTTMinted;

    constructor() ERC20('Non Transferable Oracle Token', 'nORFI') {
        redeemable = false;
        transferApprovedAddress[msg.sender] = true;
        totalNTTSupply = 5*1e24;

        totalNTTMinted = 0;
    }

    function approveAddressForTransfer(address account_) external onlyOwner {
        transferApprovedAddress[account_] = true;
    }

    function removeAddressForTransfer(address account_) external onlyOwner {
        transferApprovedAddress[account_] = false;
    }

    function setOrfiAddress(address orfiAddress_) external onlyOwner {
        orfiAddress = orfiAddress_;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(totalNTTMinted + amount <= totalNTTSupply, "Total supply will expected NTT supply");
        totalNTTMinted += amount;
        _mint(account, amount);
    }

    function burn(uint256 amount_) external {
        _burn(msg.sender, amount_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override view {
        if(from != address(0) && to != address(0)){
            require(transferApprovedAddress[from], "Transfer not allowed by caller");
        }
    }

    function redeemORFI(uint256 amount_) external {
        require(redeemable, "Redeem is not allowed");
        _burn(msg.sender, amount_);

        totalOrfiRedeemed += amount_;

        IERC20(orfiAddress).transfer(msg.sender, amount_);
        emit Redeemed(msg.sender, amount_);
    }

    function toggleRedeemFlag() external onlyOwner {
        redeemable = !redeemable;
        emit RedeemedStatus(redeemable);
    }
}
