// SPDX-License-Identifier: MIT

import "contracts/SampleToken.sol";

pragma solidity ^0.8.0;

contract ProductIdentification {
    address public owner;
    
    mapping(address => bool) public suppliers;
    mapping(bytes4 => Product) public products;
    uint256 public registrationFee;

    SampleToken public token;  // Reference to your custom token contract

    struct Product {
        bytes4 id;
        string name;
        uint256 volume;
        address owner;
    }

    constructor(uint256 _registrationFee, address _tokenAddress) {
        owner = msg.sender;
        registrationFee = _registrationFee;
        token = SampleToken(_tokenAddress);  // Initialize the token contract
    }

    function setRegistrationFee(uint256 _newRegistrationFee) public {
        require(msg.sender == owner);
        require(_newRegistrationFee > 0, "Registration fee must be greater than 0");
        registrationFee = _newRegistrationFee;
    }

    function registerSuppliers() public {
        require(!supplierIsRegistered(msg.sender), "Supplier is already registered");

        // Transfer registration fee in tokens
        require(token.transferFrom(msg.sender, owner, registrationFee), "Token transfer failed");

        suppliers[msg.sender] = true;
    }

    function registerProduct(string memory _name, uint256 _amount) public returns (bytes4){
        require(supplierIsRegistered(msg.sender), "Supplier is not registered");

        bytes4 _id = bytes4(keccak256(abi.encodePacked(msg.sender, _name)));
        require(!productExist(_id), "Product is already registered");

        products[_id] = Product(_id, _name, _amount, msg.sender);

        return _id;
    }

    function supplierIsRegistered(address _supplier) public view returns (bool)
    {
        return suppliers[_supplier];
    }

    function productExist(bytes4 _id) public view returns (bool) {
        return products[_id].owner != address(0);
    }

    function getProductInformation(bytes4 _id) external view returns (Product memory)
    {
        require(productExist(_id), "Product doesn't exist");
        return products[_id];
    }
}