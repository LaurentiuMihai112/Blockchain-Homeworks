pragma solidity ^0.8.0;

import "./ProductIdentification.sol";

contract ProductStore {
    address public owner;
    address public identificationContractAddress;
    address public depositContractAddress;
    
    struct Product {
        uint pricePerUnit;
        uint quantity;
    }
    
    mapping(bytes4 => Product) public storeInventory;

    constructor(address _identificationContract, address _depositContract) {
        owner = msg.sender;
        identificationContractAddress = _identificationContract;
        depositContractAddress = _depositContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyAuthorizedProducer(bytes4 _productId) {
        (address producerAddress, , ) = ProductIdentification(identificationContractAddress).getProductInfo(_productId);
        require(producerAddress == msg.sender, "You are not an authorized producer for this product");
        _;
    }

    function addProductToStore(bytes4 _productId, uint _pricePerUnit, uint _quantity) public onlyAuthorizedProducer(_productId) {
        Product storage product = storeInventory[_productId];
        product.pricePerUnit = _pricePerUnit;
        product.quantity += _quantity;
    }
        
    function setProductPrice(bytes4 _productId, uint _pricePerUnit) public onlyAuthorizedProducer(_productId) {
        Product storage product = storeInventory[_productId];
        product.pricePerUnit = _pricePerUnit;
    }

    function checkProductAvailability(bytes4 _productId) public view returns (uint) {
        return storeInventory[_productId].quantity;
    }

    function purchaseProduct(bytes4 _productId, uint _quantity) public payable {
        Product storage product = storeInventory[_productId];
        uint totalPrice = product.pricePerUnit * _quantity;
        require(msg.value >= totalPrice, "Insufficient funds to purchase");
        require(product.quantity >= _quantity, "Product not available in sufficient quantity");
        
        product.quantity -= _quantity;
        
        // Transfer half of the price to the producer
        (address producerAddress, , ) = ProductIdentification(identificationContractAddress).getProductInfo(_productId);
        payable(producerAddress).transfer(totalPrice / 2);
        
        // Return any excess funds to the buyer
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }
}
