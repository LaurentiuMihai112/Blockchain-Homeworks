pragma solidity ^0.8.0;

contract ProductIdentification {
    address public owner;
    uint256 public registrationFee;
    mapping(address => bool) public registeredProducers;
    mapping(bytes4 => Product) public products;

    struct Product {
        address producer;
        bytes4 productId;
        string productName;
        uint256 volume;
    }

    constructor(uint256 _registrationFee) {
        owner = msg.sender;
        registrationFee = _registrationFee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function registerProducer(
        address _producerAddress
    ) public payable {
        require(msg.value == registrationFee, "Registration fee not paid.");
        require(
            !registeredProducers[_producerAddress],
            "Producer already registered"
        );

        registeredProducers[_producerAddress] = true;
    }

    function registerProduct(string memory _productName, uint _volume,bytes4 productId) public {
        require(registeredProducers[msg.sender], "Only registered producers can add products");
        products[productId] = Product(msg.sender,productId, _productName, _volume);
    }


    function isProducerRegistered(address _producerAddress) public view returns (bool)
    {
        return registeredProducers[_producerAddress];
    }

    function getProductInfo(bytes4 _productId) public view returns (address,string memory,uint256 )
    {
        Product memory product = products[_productId];
        return (product.producer, product.productName, product.volume);
    }

    function getProducerAddress(bytes4 _productId)
        public
        view
        returns (address)
    {
        Product memory product = products[_productId];
        return product.producer;
    }

}
