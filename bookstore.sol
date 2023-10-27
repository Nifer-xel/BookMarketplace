// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BookListing.sol";
import "./BookAuction.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BookStore is BookListing, BookAuction {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function _makePayment(address seller, uint256 amount) internal {
        uint256 fee = amount.div(10); 
        balances[owner()] = balances[owner()].add(fee);
        balances[seller] = balances[seller].add(amount.sub(fee));
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "You have no funds to withdraw");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
