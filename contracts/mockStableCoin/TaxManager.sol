pragma solidity ^0.8.0;

contract TaxManager {

    constructor () {

    }

    function isUserTaxExempted(address user) external view returns(bool) {
        return true;
    }
}
