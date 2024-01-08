// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/Auction.sol";
import "contracts/ProductIdentification.sol";
import "contracts/SampleToken.sol";

contract MyAuction is Auction {
    ProductIdentification public productIdentification;
    SampleToken public tokenContract;

    bool private auctionStarted;
    mapping(address => bool) public hasBid;

    constructor( address _contractAddress, uint256 _biddingTime, address payable _owner, string memory _brand, string memory _Rnumber, address _tokenContractAddress) {
        productIdentification = ProductIdentification(_contractAddress);
        require(productIdentification.productExists(_brand), "Car brand is not registered as a product");
        require(!auctionStarted, "Auction already started");

        auction_owner = _owner;
        auction_start = block.timestamp;
        auction_end = auction_start + _biddingTime * 1 hours;
        STATE = auction_state.STARTED;
        Mycar.Brand = _brand;
        Mycar.Rnumber = _Rnumber;
        auctionStarted = true;

        tokenContract = SampleToken(_tokenContractAddress);
    }

    function bid(uint256 _tokenAmount) public an_ongoing_auction override returns (bool) {
        require(!hasBid[msg.sender], "You can only bid once");
        require(tokenContract.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        require(bids[msg.sender] + _tokenAmount > highestBid, "You can't bid, Make a higher Bid");

        hasBid[msg.sender] = true;
        highestBidder = msg.sender;
        highestBid = bids[msg.sender] + _tokenAmount;
        bidders.push(msg.sender);
        bids[msg.sender] = highestBid;

        emit BidEvent(highestBidder, highestBid);
        return true;
    }

    function finalizeAuction() external only_owner returns (bool) {
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED, "Auction is still open");

        if (highestBid > 0) {
            require(tokenContract.transfer(auction_owner, highestBid), "Token transfer to owner failed");
        }

        for (uint256 i = 0; i < bidders.length; i++) {
            if (bidders[i] != highestBidder) {
                uint256 refundAmount = bids[bidders[i]];
                if (refundAmount > 0) {
                    require(tokenContract.transfer(bidders[i], refundAmount), "Token refund to bidder failed");
                }
            }
        }

        selfdestruct(auction_owner);
        return true;
    }
}
