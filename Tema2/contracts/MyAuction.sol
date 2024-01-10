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
        require(productIdentification.brandExists(_brand), "Car brand is not registered as a product");
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
        require(bids[msg.sender] + _tokenAmount > highestBid, "You can't bid, Make a higher Bid");
        require(tokenContract.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");

        hasBid[msg.sender] = true;
        highestBidder = msg.sender;
        highestBid = bids[msg.sender] + _tokenAmount;
        bidders.push(msg.sender);
        bids[msg.sender] = highestBid;

        emit BidEvent(highestBidder, highestBid);
        return true;
    }

    function get_owner() public view returns(address) {
        return auction_owner;
    }

    function finalizeAuction() external only_owner returns (bool) {
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED, "Auction is still open");

        if (highestBid > 0) {
            require(tokenContract.transferFrom(address(this), auction_owner, highestBid), "Token transfer to owner failed");
        }

        for (uint256 i = 0; i < bidders.length; i++) {
            if (bidders[i] != highestBidder) {
                uint256 refundAmount = bids[bidders[i]];
                if (refundAmount > 0) {
                    require(tokenContract.transferFrom(address(this), bidders[i], refundAmount), "Token refund to bidder failed");
                }
            }
        }

        selfdestruct(auction_owner);
        return true;
    }



    
    function withdraw() public override returns (bool) {
        
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED,"You can't withdraw, the auction is still open");

        uint amount = bids[msg.sender];
        bids[msg.sender] = 0;
        
        require(tokenContract.transferFrom(address(this), msg.sender, amount), "Token withdrawal failed");
        emit WithdrawalEvent(msg.sender, amount);
        return true;
      
    }

    function cancel_auction() external only_owner an_ongoing_auction override returns (bool) {
    
        STATE = auction_state.CANCELLED;
        emit CanceledEvent("Auction Cancelled", block.timestamp);
        return true;
    }
    
    function destruct_auction() external only_owner returns (bool) {
        
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED,"You can't destruct the contract,The auction is still open");
        for(uint i = 0; i < bidders.length; i++)
        {
            assert(bids[bidders[i]] == 0);
        }

        selfdestruct(auction_owner);
        return true;
    
    }
    
    fallback () external payable {
        
    }
    
    receive () external payable {
        
    }
}
