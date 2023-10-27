// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BookListing is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    struct Book {
        string title;
        uint256 price;
        string coverHash;
        string contentHash;
        address originalSeller;
        uint8 royaltyPercentage;
    }

    Counters.Counter private _bookIds;
    mapping(uint256 => Book) public books;

    constructor() ERC721("BookStore", "BOOK") {}

    function listBook(
        string memory title,
        uint256 priceInEth,
        string memory coverHash,
        string memory contentHash,
        uint8 royaltyPercentage
    ) external returns (uint256) {
        uint256 priceInWei = priceInEth * 1e18;

        _bookIds.increment();
        uint256 newBookId = _bookIds.current();

        _mint(msg.sender, newBookId);
        books[newBookId] = Book({
            title: title,
            price: priceInWei,
            coverHash: coverHash,
            contentHash: contentHash,
            originalSeller: msg.sender,
            royaltyPercentage: royaltyPercentage
        });

        return newBookId;
    }

    function delist(uint256 bookId) external {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        books[bookId].price = 0;
    }

    function getBookContent(uint256 bookId) external view returns (string memory) {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        return books[bookId].contentHash;
    }

    function getBookCover(uint256 bookId) external view returns (string memory) {
        return books[bookId].coverHash;
    }

    function setBookPrice(uint256 bookId, uint256 newPriceInEth) external {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");

        uint256 newPriceInWei = newPriceInEth * 1e18;
        books[bookId].price = newPriceInWei;
    }
}
