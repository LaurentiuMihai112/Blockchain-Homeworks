pragma solidity ^0.8.0;

import "./ProductIdentification.sol";

contract ProductDeposit {
    address public owner;
    uint public storageFee;
    uint public maxStorageVolume;
    address private identificationContractAddress = 0x5A86858aA3b595FD6663c2296741eF4cd8BC4d01;

    struct Deposit {
        address producer;
        uint quantity;
    }

    // Add a mapping to store the authorized stores for each producer
    mapping(address => address) public authorizedStores;

    mapping(bytes4 => Deposit) public productDeposits;

    constructor(uint _storageFee, uint _maxStorageVolume) {
        owner = msg.sender;
        storageFee = _storageFee;
        maxStorageVolume = _maxStorageVolume;
    }

    modifier AuthorizedProducer(bytes4 _productId) {
        (address producerAddress, , ) = ProductIdentification(identificationContractAddress).getProductInfo(_productId);
        require(producerAddress == msg.sender, "You are not an authorized producer for this product");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function depositProduct(bytes4 _productId, uint _quantity) public payable AuthorizedProducer(_productId) {
        require(msg.value == _quantity * storageFee, "Storage fee not paid.");
        require(_quantity <= maxStorageVolume, "Quantity exceeds maximum storage volume");

        Deposit storage deposit = productDeposits[_productId];
        deposit.producer = msg.sender;
        deposit.quantity += _quantity;
    }

    function withdrawProduct(bytes4 _productId, uint _quantity) public {
        require(msg.sender == productDeposits[_productId].producer || authorizedStores[msg.sender]==msg.sender, "Not authorized to perform this action");
        Deposit storage deposit = productDeposits[_productId];
        require(deposit.producer == msg.sender, "You are not the producer");
        require(_quantity <= deposit.quantity, "Insufficient quantity in deposit");

        deposit.quantity -= _quantity;
    }

    function authorizeStore(address _storeAddress) public {
        require(msg.sender == owner || msg.sender == authorizedStores[msg.sender], "Not authorized to perform this action");
        authorizedStores[msg.sender] = _storeAddress;
    }


}
