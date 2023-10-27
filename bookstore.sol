// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBookStore.sol";

contract BookStore is ERC721Enumerable, Ownable, IBookStore {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _bookIds;

    struct Book {
        string title;
        uint256 price;
        string coverHash;
        string contentHash;
        address originalSeller;
        uint8 royaltyPercentage;
        uint256 auctionEndTime;
        address highestBidder;
        uint256 highestBid;
        uint256 startPrice;
        bool auctionEnded;
    }

    mapping(uint256 => Book) public books;
    mapping(address => uint256) public balances;

    constructor() ERC721("BookStore", "BOOK") {}

    function makePayment(address seller, uint256 amount) external override {
        uint256 fee = amount.div(10);
        balances[owner()] = balances[owner()].add(fee);
        balances[seller] = balances[seller].add(amount.sub(fee));
    }

    function withdraw() external override {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "You have no funds to withdraw");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function listBook(
        string memory title,
        uint256 priceInEth,
        string memory coverHash,
        string memory contentHash,
        uint8 royaltyPercentage
    ) external override returns (uint256) {
        // ...
    }

    function delist(uint256 bookId) external override {
        // ...
    }

    function getBookContent(uint256 bookId) external view override returns (string memory) {
        // ...
    }

    function getBookCover(uint256 bookId) external view override returns (string memory) {
        // ...
    }

    function buyBook(uint256 bookId) external payable override {
        // ...
    }

    function setBookPrice(uint256 bookId, uint256 newPriceInEth) external override {
        // ...
    }

    // Аукционные функции
    function startAuction(uint256 bookId, uint256 durationInHours, uint256 startPriceInEth) external override {
        // ...
    }

    function bid(uint256 bookId) external payable override {
        // ...
    }

    function auctionEndTime(uint256 bookId) external view override returns (uint256) {
        // ...
    }

    function endAuction(uint256 bookId) external override {
        // ...
    }

    function owner() public view override(IBookStore, Ownable) returns (address) {
        return Ownable.owner();
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721, IBookStore) returns (address) {
    return super.ownerOf(tokenId);
    }

    function getOriginalSeller(uint256 bookId) external view override returns (address) {
    return books[bookId].originalSeller;
    }

    function getRoyalty(uint256 bookId) external view override returns (uint256) {
    return books[bookId].royaltyPercentage;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
        )  public override(ERC721, IERC721, IBookStore) {
        super.safeTransferFrom(from, to, tokenId);
    }
}
