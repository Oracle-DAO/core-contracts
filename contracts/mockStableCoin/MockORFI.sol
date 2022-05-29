// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockORFI is ERC20 {

    address public owner;
    address public nttContractAddress;
    using SafeMath for uint256;

    constructor() ERC20('Oracle', 'ORFI') {
        owner = msg.sender;
    }

    function setNttContractAddress(address nttContractAddress_) external {
        require(msg.sender == owner, "Caller is not Owner");
        require(nttContractAddress_ != address(0));
        nttContractAddress = nttContractAddress_;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == owner || msg.sender == nttContractAddress, "Caller is not invalid");
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
}
