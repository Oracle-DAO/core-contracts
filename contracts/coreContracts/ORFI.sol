// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VaultOwned is Ownable {
    address internal _vault;

    event VaultTransferred(address indexed newVault);

    function setVault(address vault_) external onlyOwner {
        require(vault_ != address(0), 'IA0');
        _vault = vault_;
        emit VaultTransferred(_vault);
    }

    function vault() public view returns (address) {
        return _vault;
    }

    modifier onlyVault() {
        require(_vault == msg.sender, 'VaultOwned: caller is not the Vault');
        _;
    }
}

contract ORFI is  Context, VaultOwned, ERC20 {

    using SafeMath for uint256;

    constructor() ERC20('Oracle', 'ORFI') {}

    function mint(address account, uint256 amount) external onlyVault {
        _mint(account, amount);
    }

    function burnFrom(address account_, uint256 amount_) external {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(amount_);
        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}
