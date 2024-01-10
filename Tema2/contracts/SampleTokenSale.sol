// SPDX-License-Identifier: MIT

import "contracts/SampleToken.sol";

pragma solidity ^0.8.0;

contract SampleTokenSale {
    SampleToken public tokenContract;
    uint256 public tokenPrice;
    address owner;

    uint256 public tokensSold;

    event Sell(address indexed _buyer, uint256 indexed _amount);

    constructor(SampleToken _tokenContract, uint256 _tokenPrice) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        uint256 totalCost = _numberOfTokens * tokenPrice;

        require(_numberOfTokens > 0, "Number of tokens must be greater than zero");
        require(msg.value >= totalCost, "Insufficient funds sent");
        require(tokenContract.allowance(owner, address(this)) >= _numberOfTokens, "Not enough allowance");
        require(tokenContract.transferFrom(owner, msg.sender, _numberOfTokens), "Token transfer failed");

        tokensSold += _numberOfTokens;
        uint256 refundAmount = msg.value - totalCost;

        emit Sell(msg.sender, _numberOfTokens);

        // Return the excess funds to the buyer
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function endSale() public {
        require(
            tokenContract.transfer(
                owner,
                tokenContract.balanceOf(address(this))
            )
        );
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTokenPrice(uint256 _newPrice) public {
        require(msg.sender == owner, "Only the owner can set the token price");
         require(_newPrice > 0, "New token price must be greater than zero");
        tokenPrice = _newPrice;
    }
}
