// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BookListing.sol";

contract BookAuction is BookListing {
    struct Auction {
        uint256 auctionEndTime;
        address highestBidder;
        uint256 highestBid;
        uint256 startPrice;
        bool auctionEnded;
    }

    mapping(uint256 => Auction) public auctions;

    function startAuction(
        uint256 bookId,
        uint256 durationInHours,
        uint256 startPriceInEth
    ) external {
        require(ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        Book storage book = books[bookId];
        require(book.price > 0, "Book not listed for sale");

        auctions[bookId] = Auction({
            auctionEndTime: block.timestamp + durationInHours * 1 hours,
            highestBidder: address(0),
            highestBid: 0,
            startPrice: startPriceInEth * 1e18,
            auctionEnded: false
        });
    }

    function bid(uint256 bookId) external payable {
        Auction storage auction = auctions[bookId];
        Book storage book = books[bookId];

        require(book.price > 0, "Book not listed for sale");
        require(block.timestamp < auction.auctionEndTime, "Auction already ended");
        require(msg.value > auction.highestBid, "There already is a higher bid");
        require(msg.value >= auction.startPrice, "Bid is lower than the start price");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }

    function auctionEndTime(uint256 bookId) external view returns (uint256) {
        Auction storage auction = auctions[bookId];

        if (auction.auctionEndTime == 0 || block.timestamp > auction.auctionEndTime) {
            return 0;
        }
        return (auction.auctionEndTime - block.timestamp) / 60;
    }

    function endAuction(uint256 bookId) external {
        Auction storage auction = auctions[bookId];
        Book storage book = books[bookId];

        require(
            ownerOf(bookId) == msg.sender || block.timestamp >= auction.auctionEndTime,
            "Only owner can end auction early"
        );
        require(book.price > 0, "Book not listed for sale");
        require(!auction.auctionEnded, "Auction already ended");

        auction.auctionEnded = true;
        book.price = 0;

        if (auction.highestBidder != address(0)) {
            uint256 royaltyAmount = (auction.highestBid * book.royaltyPercentage) / 100;
            _makePayment(msg.sender, auction.highestBid - royaltyAmount);
            _makePayment(book.originalSeller, royaltyAmount);

            _bookIds.increment();
            uint256 newBookId = _bookIds.current();
            _mint(auction.highestBidder, newBookId);
            books[newBookId] = Book({
                title: book.title,
                price: 0,
                coverHash: book.coverHash,
                contentHash: book.contentHash,
                originalSeller: book.originalSeller,
                royaltyPercentage: book.royaltyPercentage
            });
        }
    }
}
