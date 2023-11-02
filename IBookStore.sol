// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBookStore {
    function owner() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function withdraw() external;
    function listBook(
    string memory title, 
    uint256 priceInEth, 
    string memory coverHash, 
    string memory contentHash, 
    uint8 royaltyPercentage
) external returns (uint256);  // добавлен возвращаемый тип


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getRoyalty(uint256 bookId) external view returns (uint256);

    function getOriginalSeller(uint256 bookId) external view returns (address);

    function delist(uint256 bookId) external;
    function getBookContent(uint256 bookId) external view returns (string memory);
    function getBookCover(uint256 bookId) external view returns (string memory);
    function buyBook(uint256 bookId) external payable;
    function setBookPrice(uint256 bookId, uint256 newPriceInEth) external;

    // Аукционные функции
    function startAuction(uint256 bookId, uint256 durationInHours, uint256 startPriceInEth) external;
    function bid(uint256 bookId) external payable;
    function auctionEndTime(uint256 bookId) external view returns (uint256);
    function endAuction(uint256 bookId) external;
}
