// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MIM is Ownable, ERC20{
    using SafeMath for uint256;

    constructor() ERC20('Oracle', 'ORCL') {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
