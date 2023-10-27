// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBookStore.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BookListing is IERC721Receiver {
    IBookStore public bookStore;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    event BookListed(uint256 bookId, address seller, uint256 price);
    event BookDelisted(uint256 bookId);
    event BookSold(uint256 bookId, address buyer, uint256 price);

    constructor(address _bookStore) {
        bookStore = IBookStore(_bookStore);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function listBook(uint256 bookId, uint256 price) external {
        require(bookStore.ownerOf(bookId) == msg.sender, "You are not the owner of the book");
        bookStore.safeTransferFrom(msg.sender, address(this), bookId);
        listings[bookId] = Listing({seller: msg.sender, price: price});
        emit BookListed(bookId, msg.sender, price);
    }

    function delistBook(uint256 bookId) external {
        Listing memory listing = listings[bookId];
        require(listing.seller == msg.sender, "You are not the seller");
        bookStore.safeTransferFrom(address(this), listing.seller, bookId);
        delete listings[bookId];
        emit BookDelisted(bookId);
    }

    function buyBook(uint256 bookId) external payable {
        Listing memory listing = listings[bookId];
        require(listing.price > 0, "Book not listed");
        require(msg.value >= listing.price, "Insufficient funds");
        bookStore.safeTransferFrom(address(this), msg.sender, bookId);
        uint256 royalty = bookStore.getRoyalty(bookId);
        uint256 sellerAmount = listing.price - royalty;
        address originalSeller = bookStore.getOriginalSeller(bookId);
        payable(originalSeller).transfer(royalty);
        payable(listing.seller).transfer(sellerAmount);
        if (msg.value > listing.price) {
            uint256 change = msg.value - listing.price;
            payable(msg.sender).transfer(change);
        }
        delete listings[bookId];
        emit BookSold(bookId, msg.sender, listing.price);
    }
}
