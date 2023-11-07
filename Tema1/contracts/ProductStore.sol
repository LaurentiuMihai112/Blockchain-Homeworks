// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProductIdentification.sol";
import "./ProductDeposit.sol";

contract ProductStore {
    address public owner;
    ProductIdentification public identificationContract;
    ProductDeposit public depositContract;
    Product[] products;
    
    struct Product {
        bytes4 id;
        uint pricePerUnit;
        uint quantity;
        address owner;
    }
    

    constructor(address _identificationContract, address _depositContract) {
        owner = msg.sender;
        identificationContract = ProductIdentification(_identificationContract);
        depositContract = ProductDeposit(_depositContract);
    }

    modifier onlyAuthorizedProducer(bytes4 _productId) {
        (,,,address producerAddress) = identificationContract.getProductInformation(_productId);
        require(producerAddress == msg.sender, "You are not an authorized producer for this product");
        _;
    }

    function addProductToStore(bytes4 _productId, uint _pricePerUnit, uint _quantity) public onlyAuthorizedProducer(_productId) {
        require(depositContract.withdrawProduct(_productId,_quantity),"You were not authorized for withdrawing from the deposit");
        products.push(Product(_productId, _pricePerUnit, _quantity, msg.sender));
    }
        
    function setProductPrice(bytes4 _productId, uint _pricePerUnit) public onlyAuthorizedProducer(_productId) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _productId) {
                products[i].pricePerUnit = _pricePerUnit;
            }
        }
    }

    function checkAvailability(bytes4 _productId) public view returns (uint){
        int _quantity = productExistsInStore(_productId);
        require(_quantity != -1, "Product does not exist in store");
        return uint(_quantity);
    }


    function purchaseProduct(bytes4 _productId, uint _quantity) public payable {
        int quantity = productExistsInStore(_productId);
        require(quantity != -1, "Product does not exist in store");
        require(_quantity <= uint(quantity),"There is not enough quantity");
        require(_quantity > 0,"Quantity to be bought must be positive");
        Product storage product = products[getProduct(_productId)];
        require(msg.value >= product.pricePerUnit * _quantity, "Not enough funds");
        product.quantity -= _quantity;

        uint change = msg.value - product.pricePerUnit * _quantity;

        payable(msg.sender).transfer(change);

        payable(product.owner).transfer((product.pricePerUnit * _quantity / 2));

    }

    function productExistsInStore(bytes4 _productId) private view returns (int){
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _productId) {
                return int(products[i].quantity);
            }
        }
        return -1;
    }

    function getProduct(bytes4 _productId) private view returns (uint){
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _productId) {
                return i;
            }
        }
    }

}
