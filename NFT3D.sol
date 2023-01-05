// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INFT3D{
    function printNFT(uint _NFTCollection, uint _amount, uint _size, uint _printingFee, string memory _material, address _store) external returns(bool);
    function mintNFT(uint _amount, string memory _uri) external payable returns(bool);
    function updateURI(uint _NFTCollection, string memory _newURI) external returns(bool);
}

contract NFT3D is IERC1155, ERC1155{

    address owner;
    // 1st NFT collection will be number 0 by default.
    uint private NFTcount;
    // Fee for minting a collection.
    uint public mintingFee;
    // Array with all the creators. It would be userful for Airdrops.
    address[] private creators;

    // NFTidCollection -> URIs array. (It will contain STL file & 3D details choosen by the user).
    mapping(uint => string) private UriToPrint;
    // NFTidCollection -> Creator
    mapping(uint => address) public CheckCreator;
    // NFTidCollection -> NFTAmount (It will return the amount of NFTs created for a Colection) Example. 1 Shoes model, 10 available.
    mapping(uint => uint) public NFTsMinted;
    // NFTidCollection -> NFTsRemainingToBurn (It will return the amount of NFTs waiting to be burned)
    mapping(uint => uint) public NFTsRemainingBurn;
    // NFTidCollection -> Request URI -> owner or creator -> Accepted.
    mapping(uint => mapping(string => mapping(address => bool))) changeURIRequest;
    // Creator address => array of his NFT Collections ID.
    mapping(address => uint[]) public CollectionsPerAddres;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event URI3DBurned(address indexed Owner, uint NFTCollection, string URI, uint Size, string Material, address Store, uint BurningTime);
    event NFTMinted(address indexed Owner, uint NFTCollection, uint NumberCollectionsCreator, uint Amount, uint MintingTime);
    event URIUpdated(uint NFTCollection, string NewURI, uint UpdateTime);
    event MintingFeeUpdated(uint NewMintingFee, uint UpdateTime); 
    event NewCreator(address indexed Creator, uint FirstCreationTime);
    event foundsWithdrawn(address indexed Owner, uint EthersWithdrawn, uint WithdrawnTime);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "You`r not the owner");
        _;
    }

    constructor() ERC1155(""){}

    /**
     * @dev Minting function. It will set the URI, NFT Collection & amount of NFTs created.
     * @param _amount: Total amount of NFTs we want to mint. (Same NFT Collection)
     * @param _uri: Uri we want to set as the default URI when burned.
     */
    function mintNFT(uint _amount, string memory _uri) external payable returns(bool){
        require(msg.value >= mintingFee, "You need to pay Minting Fee");
        _mint(msg.sender, NFTcount, _amount, "");
        NFTsMinted[NFTcount] = _amount;
        NFTsRemainingBurn[NFTcount] = _amount;
        CheckCreator[NFTcount] = msg.sender;
        UriToPrint[NFTcount] = _uri;
        CollectionsPerAddres[msg.sender].push(NFTcount);

        for(uint i; i < creators.length; i++) {
            if(creators[i] != msg.sender) {  
                creators.push(msg.sender);
                emit NewCreator(msg.sender, block.timestamp);

            }
        }
        
        emit NFTMinted(msg.sender, NFTcount, CollectionsPerAddres[msg.sender].length, _amount, block.timestamp);
        NFTcount++;

        return true;
    }

    /**
     * @dev Burning function to burn the token, pays the fee for the burining & emits the URI to print.
     *      If we choose more than 1 NFT, it will print all of them under the same conditions.
     * @param _NFTCollection: NFT Collection Identifier.
     * @param _amount: Total amount of NFTs we want to print. (Same NFT Collection)
     * @param _size: Desirable size for the NFT printed.
     * @param _printingFee: Printing Fee stablished by the Grams & Material.
     * @param _material: Desirable material for the NFT printed.
     * @param _store: Print store where we want to print the NFT.
     */
    function printNFT(uint _NFTCollection, uint _amount, uint _size, uint _printingFee, string memory _material, address _store) external payable returns(bool){
        require(msg.value == _printingFee, "Pay printingFee");
        payable(_store).transfer(_printingFee);
        _burn(msg.sender, _NFTCollection, _amount);
        string memory _uri = UriToPrint[_NFTCollection];
        NFTsRemainingBurn[_NFTCollection] -= _amount;

        emit URI3DBurned(msg.sender, _NFTCollection, _uri, _size, _material, _store, block.timestamp);
        return true;
    }

    /**
     * @dev Withdrawn function to extract from the contract the Fees paid for minting 3D NFts.
     * @param _amount: Amount in Ethers choosen to withdrawn.
     */
    function withdrawnFunds(uint _amount, address _to) public onlyOwner returns(bool) {
        payable(_to).transfer(_amount);
        emit foundsWithdrawn(msg.sender, _amount, block.timestamp);
        return true;
    }

    /**
     * @dev Setter for new URI. It needs the agreement of the contract Owner & NFT Creator.
     * @param _NFTCollection: NFT Collection Identifier.
     * @param _newURI: New URI we want to update for the NFT Collection ID.
     */
    function updateURI(uint _NFTCollection, string memory _newURI) external returns(bool) {
        require(msg.sender == owner || CheckCreator[_NFTCollection] == msg.sender, "You can`t update URI");
        require(!changeURIRequest[_NFTCollection][_newURI][msg.sender], "You already approved");
        changeURIRequest[_NFTCollection][_newURI][msg.sender] = true;
        if(changeURIRequest[_NFTCollection][_newURI][owner] && changeURIRequest[_NFTCollection][_newURI][CheckCreator[_NFTCollection]]) {
            UriToPrint[_NFTCollection] = _newURI;
        }

        emit URIUpdated(_NFTCollection, _newURI, block.timestamp);
        return true;
    }

    /**
     * @dev Setter for the Minting fee the creator needs to pay per collection
     * @param _newMintingFee: New Fee to set.
     */
    function updateMintFee(uint _newMintingFee) external onlyOwner returns(bool){
        mintingFee = _newMintingFee;
        emit MintingFeeUpdated(_newMintingFee, block.timestamp);
        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *      Can only be called by the current owner.
     * @param newOwner: New Owner address to set.
     */
    function transferOwnership(address payable newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        return true;
    }
}
    // THINGS TO ADD: 
    
    // - Minting fee PER COLLECTION OR PER AMOUNT NFTs CREATED FOR THE COLLECTION???
  
    // - When the user burns the NFT, he must pay a printing fee, but the function can be called by the NFT owner 
    // from other DApp and choose the printing fee as 0. It will burn the token anyway, 
    // but the printing company won´t print it as he did not pay enough for it.
  
    // - WOULD YOU LIKE TO HAVE AN ARRAY WITH DIFFERENTS Admins? EACH OWNER CAN HAVE A ROLE IN THE CONTRACT
    // Example: 1 Owner can withdrawn the funds, but others can only update fees.

    /**
     * @dev 
     * @param   
     */
