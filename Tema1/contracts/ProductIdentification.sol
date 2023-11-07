// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract ProductIdentification {
    address public owner;

    address[] suppliers;
    Product[] products;
    uint public registrationFee;

    struct Product {
        bytes4 id;
        string name;
        uint volume;
        address owner;
    }

    constructor(uint _registrationFee) {
        owner = msg.sender;

        registrationFee = _registrationFee;
    }

    function registerSuppliers() public payable {
        require(!supplierIsRegistered(), "Supplier is already registered");
        require(msg.value >= registrationFee, "Value must be greater than 0");

        uint change = msg.value - registrationFee;


        suppliers.push(msg.sender);

        payable(owner).transfer(registrationFee);

        if(change != 0){
            payable(msg.sender).transfer(uint(change));
        }

    }

    function registerProduct(string memory _name, uint _amount) public {
        require(supplierIsRegistered(), "Supplier is not registered");
        
        bytes4 _id = bytes4(keccak256(abi.encodePacked(msg.sender, _name)));
        require(!productExist(_id), "Product is already registered");

        products.push(Product(_id, _name, _amount, msg.sender));
    }

    function supplierIsRegistered(address _supplier) public view returns (bool) {
        for (uint i = 0; i < suppliers.length; i++) {
            if (suppliers[i] == _supplier) {
                return true;
            }
        }

        return false;
    }
    function supplierIsRegistered() public view returns (bool) {
        for (uint i = 0; i < suppliers.length; i++) {
            if (suppliers[i] == msg.sender) {
                return true;
            }
        }

        return false;
    }

    function getProducts() public view returns (Product[] memory) {
        return products;
    }

    function getSuppliers() public view returns (address[] memory) {
        return suppliers;
    }

    function productExist(bytes4 _id) public view returns (bool) {
        // require(supplierIsRegistered(), "Supplier is not registered");

        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return true;
            }
        }

        return false;
    }

    function getProductInformation(bytes4 _id) external view returns (bytes4, string memory, uint, address) {
        // require(supplierIsRegistered(), "Supplier is not registered");
        require(productExist(_id), "Product doesn't exist");

        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                return (products[i].id, products[i].name, products[i].volume, products[i].owner);
            }
        }
    }
    function updateQuantity(bytes4 _id, int _quantity, address supplier) public {
        require(supplierIsRegistered(supplier), "Supplier is not registered");

        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) {
                products[i].volume = uint(int(products[i].volume) + _quantity);
            }
        }
    }

}