// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Supply Chain Tracker
 * @dev A smart contract to track products through the supply chain
 * @author Supply Chain Tracker Team
 */
contract SupplyChainTracker {
    
    // Enum to represent different stages of the supply chain
    enum Stage {
        Manufactured,
        InTransit,
        Delivered,
        Sold
    }
    
    // Struct to represent a product
    struct Product {
        uint256 id;
        string name;
        string manufacturer;
        uint256 manufacturingDate;
        Stage currentStage;
        address currentOwner;
        string location;
        bool exists;
    }
    
    // State variables
    mapping(uint256 => Product) public products;
    mapping(uint256 => address[]) public productHistory;
    uint256 public productCounter;
    address public owner;
    
    // Events
    event ProductRegistered(
        uint256 indexed productId,
        string name,
        string manufacturer,
        address indexed owner
    );
    
    event StageUpdated(
        uint256 indexed productId,
        Stage newStage,
        address indexed updatedBy,
        string location
    );
    
    event OwnershipTransferred(
        uint256 indexed productId,
        address indexed previousOwner,
        address indexed newOwner
    );
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(products[_productId].exists, "Product does not exist");
        _;
    }
    
    modifier onlyProductOwner(uint256 _productId) {
        require(
            products[_productId].currentOwner == msg.sender,
            "Only product owner can perform this action"
        );
        _;
    }
    
    constructor() {
        owner = msg.sender;
        productCounter = 0;
    }
    
    /**
     * @dev Register a new product in the supply chain
     * @param _name Name of the product
     * @param _manufacturer Name of the manufacturer
     * @param _location Initial location of the product
     * @return productId The unique ID assigned to the product
     */
    function registerProduct(
        string memory _name,
        string memory _manufacturer,
        string memory _location
    ) external returns (uint256) {
        productCounter++;
        uint256 newProductId = productCounter;
        
        products[newProductId] = Product({
            id: newProductId,
            name: _name,
            manufacturer: _manufacturer,
            manufacturingDate: block.timestamp,
            currentStage: Stage.Manufactured,
            currentOwner: msg.sender,
            location: _location,
            exists: true
        });
        
        productHistory[newProductId].push(msg.sender);
        
        emit ProductRegistered(newProductId, _name, _manufacturer, msg.sender);
        
        return newProductId;
    }
    
    /**
     * @dev Update the stage and location of a product in the supply chain
     * @param _productId ID of the product to update
     * @param _newStage New stage of the product
     * @param _location New location of the product
     */
    function updateProductStage(
        uint256 _productId,
        Stage _newStage,
        string memory _location
    ) external productExists(_productId) onlyProductOwner(_productId) {
        Product storage product = products[_productId];
        
        // Ensure stage progression is logical
        require(
            uint8(_newStage) > uint8(product.currentStage),
            "Cannot move to a previous stage"
        );
        
        product.currentStage = _newStage;
        product.location = _location;
        
        emit StageUpdated(_productId, _newStage, msg.sender, _location);
    }
    
    /**
     * @dev Transfer ownership of a product to another address
     * @param _productId ID of the product to transfer
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(
        uint256 _productId,
        address _newOwner
    ) external productExists(_productId) onlyProductOwner(_productId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        Product storage product = products[_productId];
        address previousOwner = product.currentOwner;
        
        product.currentOwner = _newOwner;
        productHistory[_productId].push(_newOwner);
        
        emit OwnershipTransferred(_productId, previousOwner, _newOwner);
    }
    
    /**
     * @dev Get detailed information about a product
     * @param _productId ID of the product to query
     * @return Product struct containing all product information
     */
    function getProduct(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (Product memory) 
    {
        return products[_productId];
    }
    
    /**
     * @dev Get the ownership history of a product
     * @param _productId ID of the product to query
     * @return Array of addresses representing the ownership history
     */
    function getProductHistory(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (address[] memory) 
    {
        return productHistory[_productId];
    }
    
    /**
     * @dev Get the current stage of a product as a string
     * @param _productId ID of the product to query
     * @return String representation of the current stage
     */
    function getProductStageString(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (string memory) 
    {
        Stage stage = products[_productId].currentStage;
        
        if (stage == Stage.Manufactured) return "Manufactured";
        if (stage == Stage.InTransit) return "In Transit";
        if (stage == Stage.Delivered) return "Delivered";
        if (stage == Stage.Sold) return "Sold";
        
        return "Unknown";
    }
    
    /**
     * @dev Get the total number of registered products
     * @return Total count of products
     */
    function getTotalProducts() external view returns (uint256) {
        return productCounter;
    }
}
