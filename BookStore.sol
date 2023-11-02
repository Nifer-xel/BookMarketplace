// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBookStore.sol";

contract BookStore is ERC721Enumerable, Ownable, IBookStore {
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

    function _makePayment(address seller, uint256 amount) internal {
        uint256 fee = amount / 10;
        balances[owner()] += fee;
        balances[seller] += amount - fee;
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
) external override returns (uint256) {  // добавлен возвращаемый тип
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
            royaltyPercentage: royaltyPercentage,
            auctionEndTime: 0,
            highestBidder: address(0),
            highestBid: 0,
            startPrice: 0,
            auctionEnded: false
        });
        return newBookId;
    }


    function delist(uint256 bookId) external override {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        books[bookId].price = 0;
    }

    function getBookContent(uint256 bookId) external view override returns (string memory) {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        return books[bookId].contentHash;
    }

    function getBookCover(uint256 bookId) external view override returns (string memory) {
        return books[bookId].coverHash;
    }

    function buyBook(uint256 bookId) external payable override {
         Book memory originalBook = books[bookId];
        require(originalBook.price > 0, "Book not listed for sale");
        require(msg.value >= originalBook.price, "Insufficient funds sent");
        require(originalBook.auctionEndTime == 0 || block.timestamp > originalBook.auctionEndTime, "Auction in progress");

        address seller = ownerOf(bookId);

        uint256 royaltyAmount = 0;
        if (seller != originalBook.originalSeller) {
            royaltyAmount = (originalBook.price * originalBook.royaltyPercentage) / 100;
        }

        uint256 sellerPayment = originalBook.price - royaltyAmount;
        _makePayment(seller, sellerPayment);

        if (royaltyAmount > 0) {
            payable(originalBook.originalSeller).transfer(royaltyAmount);
        }

        if (msg.value > originalBook.price) {
            uint256 change = msg.value - originalBook.price;
            payable(msg.sender).transfer(change);
        }

        // Создание нового токена для покупателя
        _bookIds.increment();
        uint256 newBookId = _bookIds.current();
        _mint(msg.sender, newBookId);
        books[newBookId] = Book({
            title: originalBook.title,
            price: originalBook.price,
            coverHash: originalBook.coverHash,
            contentHash: originalBook.contentHash,
            originalSeller: originalBook.originalSeller,
            royaltyPercentage: originalBook.royaltyPercentage,
            auctionEndTime: 0,
            highestBidder: address(0),
            highestBid: 0,
            startPrice: 0,
            auctionEnded: false
        });
    }

    function setBookPrice(uint256 bookId, uint256 newPriceInEth) external override {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
    
        uint256 newPriceInWei = newPriceInEth * 1e18;
        books[bookId].price = newPriceInWei;
    }

    // Аукционные функции
    function startAuction(uint256 bookId, uint256 durationInHours, uint256 startPriceInEth) external override {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        Book storage book = books[bookId];
        require(book.price > 0, "Book not listed for sale");
        require(book.auctionEndTime == 0 || block.timestamp > book.auctionEndTime, "Auction already in progress");

        book.auctionEndTime = block.timestamp + durationInHours * 1 hours;
        book.highestBidder = address(0);
        book.highestBid = 0;
        book.startPrice = startPriceInEth * 1e18;
        book.auctionEnded = false;
    }

    function bid(uint256 bookId) external payable override {
        Book storage book = books[bookId];
        require(book.price > 0, "Book not listed for sale");
        require(block.timestamp < book.auctionEndTime, "Auction already ended");
        require(msg.value > book.highestBid, "There already is a higher bid");
        require(msg.value >= book.startPrice, "Bid is lower than the start price");

        if (book.highestBidder != address(0)) {
            payable(book.highestBidder).transfer(book.highestBid);
        }

        book.highestBidder = msg.sender;
        book.highestBid = msg.value;
    }

    function auctionEndTime(uint256 bookId) external view override returns (uint256) {
        Book storage book = books[bookId];
        if (book.auctionEndTime == 0 || block.timestamp > book.auctionEndTime) {
            return 0;
        }
        return (book.auctionEndTime - block.timestamp) / 60;
    }

    function endAuction(uint256 bookId) external override {
        Book storage book = books[bookId];
        require(ownerOf(bookId) == msg.sender || block.timestamp >= book.auctionEndTime, "Only owner can end auction early");
        require(book.price > 0, "Book not listed for sale");
        require(!book.auctionEnded, "Auction already ended");
        
        book.auctionEnded = true;
        book.price = 0;

        if (book.highestBidder != address(0)) {
            uint256 royaltyAmount = (book.highestBid * book.royaltyPercentage) / 100;
            _makePayment(msg.sender, book.highestBid - royaltyAmount);
            _makePayment(book.originalSeller, royaltyAmount);
            _bookIds.increment();
            uint256 newBookId = _bookIds.current();
            _mint(book.highestBidder, newBookId);
            books[newBookId] = Book({
                title: book.title,
                price: 0,
                coverHash: book.coverHash,
                contentHash: book.contentHash,
                originalSeller: book.originalSeller,
                royaltyPercentage: book.royaltyPercentage,
                auctionEndTime: 0,
                highestBidder: address(0),
                highestBid: 0,
                startPrice: 0,
                auctionEnded: true
            });
        }
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
