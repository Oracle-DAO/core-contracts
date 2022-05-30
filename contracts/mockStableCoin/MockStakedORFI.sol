// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract MockStakedORFI is Ownable, ERC20 {

    using SafeMath for uint256;

    constructor() ERC20('Staked Oracle', 'sORFI') {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address to, uint256 amount) external virtual {
        _burn(to, amount);
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
