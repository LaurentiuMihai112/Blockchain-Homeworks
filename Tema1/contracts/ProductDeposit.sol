// SPDX-License-Identifier: MIT

import "./ProductIdentification.sol";

pragma solidity >=0.8.2 <0.9.0;

contract ProductDeposit {
    address public owner;
    uint public depositFeePerUnit;
    uint public maxVolume;
    uint public currentVolume;
    
    ProductIdentification public productIdentification;

    Product[] products;
    AuthorizedStore[] authorizedStores;

    struct Product {
        bytes4 id;
        string name;
        uint volume;
        address owner;
    }

    struct AuthorizedStore{
        address producer;
        address store;
    }


    constructor(address _productIdentification, uint _depositFeePerUnit, uint _maxVolume) {
        productIdentification = ProductIdentification(_productIdentification);
        owner = msg.sender;

        depositFeePerUnit = _depositFeePerUnit;
        maxVolume = _maxVolume;
    }

    function registerProduct(address _storeId, bytes4 _productId, uint _volume) external payable {
        (bytes4 id, string memory name, uint volume, address owner) = productIdentification.getProductInformation(_productId);

        require(owner == msg.sender, "You are not allowed to add this product");
        require(_volume <= volume, "The inserted volume exceeds the volume of this product");
        require(currentVolume + _volume <= maxVolume, "There is not enough space in the deposit");

        uint fee = _volume * depositFeePerUnit;
        require(msg.value >= fee, "You have to enter the correct price");

        productIdentification.updateQuantity(_productId, -1 * int(_volume), msg.sender);
        uint change = msg.value - fee;

        products.push(Product(id, name, _volume, owner));

        payable(msg.sender).transfer(change);
        payable(owner).transfer(fee);
    }


    function registerStore(address _storeId) public {
        require(productIdentification.supplierIsRegistered(msg.sender),"You must be a registered supplier");

        authorizedStores.push(AuthorizedStore(msg.sender,_storeId));
    }

    function withdrawProduct(bytes4 _productId, uint _volume) public {
        require(productIdentification.supplierIsRegistered(msg.sender),"You must be a registered supplier");
        require(productExists(_productId),"Product does not exist");
        Product memory product = getProduct(_productId);
        require(product.volume >= _volume,"Volume is bigger than the actual volume in storage");
        bool isStore = isAuthorizedStrore(msg.sender);
        bool isProducer = isAuthorizedStrore(msg.sender);
        require(isProducer || isStore,"You are not authorized to withdraw this product");
        if(isProducer){
            productIdentification.updateQuantity(_productId, int(_volume), msg.sender);
            product.volume -= _volume;
        }
        else{
            //magazin
        }
    }

    function getProduct(bytes4 _productId) private view returns (Product memory){
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _productId) {
                return products[i];
            }
        }
    }

    function productExists(bytes4 _productId) private view returns (bool){
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _productId) {
                return true;
            }
        }
        return false;
    }

    function isAuthorizedStrore(address sender) private view returns (bool){
        for (uint i = 0; i < authorizedStores.length; i++) {
            if (authorizedStores[i].producer == sender || authorizedStores[i].store == sender) {
                return true;
            }
        }
        return false;
    }

    function isProductOwner(address sender,bytes4 _productId) private view returns (bool){
        for (uint i = 0; i < products.length; i++) {
            if (products[i].owner == sender && products[i].id == _productId) {
                return true;
            }
        }
        return false;
    }
}