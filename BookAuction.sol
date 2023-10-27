// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BookListing.sol";
import "./IBookStore.sol";

contract BookAuction is BookListing {
    struct Auction {
        uint256 auctionEndTime;
        address highestBidder;
        uint256 highestBid;
        uint256 startPrice;
        bool auctionEnded;
    }

    mapping(uint256 => Auction) public auctions;

    event AuctionStarted(uint256 bookId, uint256 duration, uint256 startPrice);
    event BidPlaced(uint256 bookId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 bookId, address winner, uint256 winningBid);

    constructor(address _bookStoreAddress) BookListing(_bookStoreAddress) {
    }

    function startAuction(
        uint256 bookId,
        uint256 durationInHours,
        uint256 startPriceInEth
    ) external {
        require(bookStore.ownerOf(bookId) == msg.sender, "You are not the owner of this book");
        Listing memory listing = listings[bookId];
        require(listing.price > 0, "Book not listed for sale");

        auctions[bookId] = Auction({
            auctionEndTime: block.timestamp + durationInHours * 1 hours,
            highestBidder: address(0),
            highestBid: 0,
            startPrice: startPriceInEth * 1e18,
            auctionEnded: false
        });

        emit AuctionStarted(bookId, durationInHours, startPriceInEth);
    }

    function bid(uint256 bookId) external payable {
        Auction storage auction = auctions[bookId];
        Listing memory listing = listings[bookId];

        require(listing.price > 0, "Book not listed for sale");
        require(block.timestamp < auction.auctionEndTime, "Auction already ended");
        require(msg.value > auction.highestBid, "There already is a higher bid");
        require(msg.value >= auction.startPrice, "Bid is lower than the start price");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(bookId, msg.sender, msg.value);
    }

    function endAuction(uint256 bookId) external {
        Auction storage auction = auctions[bookId];
        Listing memory listing = listings[bookId];

        require(
            bookStore.ownerOf(bookId) == msg.sender || block.timestamp >= auction.auctionEndTime,
            "Only owner can end auction early"
        );
        require(listing.price > 0, "Book not listed for sale");
        require(!auction.auctionEnded, "Auction already ended");

        auction.auctionEnded = true;
        listing.price = 0;

        if (auction.highestBidder != address(0)) {
            uint256 royalty = bookStore.getRoyalty(bookId);
            uint256 sellerAmount = auction.highestBid - royalty;
            address originalSeller = bookStore.getOriginalSeller(bookId);
            payable(originalSeller).transfer(royalty);
            payable(listing.seller).transfer(sellerAmount);

            emit AuctionEnded(bookId, auction.highestBidder, auction.highestBid);
        }
    }
}
