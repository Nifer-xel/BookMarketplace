# BookMarketplace

Overview
BookStore is an Ethereum-based smart contract that utilizes the ERC721 standard for tokenizing books. It allows users to buy, sell, and trade electronic books in the form of NFT tokens. The contract also supports auctions, where users can list their books for sale through an auction.

Functions
listBook

function listBook(string memory title, uint256 priceInEth, string memory coverHash, string memory contentHash, uint8 royaltyPercentage) external returns (uint256)
List a book for sale. Creates a new NFT token for the book.

delist

function delist(uint256 bookId) external
Remove a book from sale.

getBookContent

function getBookContent(uint256 bookId) external view returns (string memory)
Get the content of a book. Available only to the token owner.

getBookCover

function getBookCover(uint256 bookId) external view returns (string memory)
Get the cover of the book.

buyBook

function buyBook(uint256 bookId) external payable
Buy a book. Creates a new NFT token for the buyer.

setBookPrice

function setBookPrice(uint256 bookId, uint256 newPriceInEth) external
Set a new price for the book.

withdraw

function withdraw() external
Withdraw funds from the user's balance.

startAuction

function startAuction(uint256 bookId, uint256 durationInHours, uint256 startPriceInEth) external
Start an auction for a book.

bid

function bid(uint256 bookId) external payable
Place a bid in an auction.

auctionEndTime

function auctionEndTime(uint256 bookId) external view returns (uint256)
Get the remaining time until the end of the auction.

endAuction

function endAuction(uint256 bookId) external
End an auction.

Installation and Testing
To test the contract, you will need to install Truffle and Ganache for local Ethereum blockchain testing.

Clone the repository and navigate to the project directory.
Install the dependencies:
bash

npm install
Run Ganache and make sure it's running on port 7545.
Run the tests:
bash

truffle test
