// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract NFT3D is ERC1155 {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event URI3DBurned(address indexed Owner, uint NFTCollection, string URI, uint Size, string Material, string Store, uint BurningTime);
    event NFTMinted(address indexed Owner, uint NFTCollection, uint Amount, uint MintingTime);
    event URIUpdated(uint NFTCollection, string NewURI, uint UpdateTime);

    address public owner;
    // 1st NFT collection will be number 0 by default.
    uint private NFTcount;
    // Fee for minting a collection.
    uint public mintingFee;

    // NFTidCollection -> URIs array. (It will contain STL file & 3D details choosen by the user).
    mapping(uint => string) private UriToPrint;
    // NFTidCollection -> Creator
    mapping(uint => address) public CheckCreator;
    // NFTidCollection -> NFTAmount (It will return the amount of NFTs created for a Colection) Example. 1 Shoes model, 10 available.
    mapping(uint => uint) NFTsMinted;
    // NFTidCollection -> NFTsRemainingToBurn (It will return the amount of NFTs waiting to be burned)
    mapping(uint => uint) NFTsRemainingBurn;
    // NFTidCollection -> Request URI -> owner or creator -> Accepted.
    mapping(uint => mapping(string => mapping(address => bool))) changeURIRequest;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor() ERC1155(""){}

    /**
     * @dev Burning function to burn the token and emit the URI to print.
     *      If we choose more than 1 NFT, it will print all of them under the same conditions.
     * @param _NFTCollection: NFT Collection Identifier.
     * @param _amount: Total amount of NFTs we want to print. (Same NFT Collection)
     * @param _size: Desirable size for the NFT printed.
     * @param _material: Desirable material for the NFT printed.
     * @param _store: Print store where we want to print the NFT.
     */
    function printNFT(uint _NFTCollection, uint _amount, uint _size, string memory _material, string memory _store) public returns(bool){
        _burn(msg.sender, _NFTCollection, _amount);
        string memory _uri = UriToPrint[_NFTCollection];
        NFTsRemainingBurn[_NFTCollection] -= _amount;

        emit URI3DBurned(msg.sender, _NFTCollection, _uri, _size, _material, _store, block.timestamp);
        return true;
    }

    /**
     * @dev Minting function. It will set the URI, NFT Collection & amount of NFTs created.
     * @param _amount: Total amount of NFTs we want to mint. (Same NFT Collection)
     * @param _uri: Uri we want to set as the default URI when burned.
     */
    function mintNFT(uint _amount, string memory _uri) public payable returns(bool){
        require(msg.value >= mintingFee, "You need to pay Minting Fee");
        _mint(msg.sender, NFTcount, _amount, "");
        NFTsMinted[NFTcount] = _amount;
        NFTsRemainingBurn[NFTcount] = _amount;
        CheckCreator[NFTcount] = msg.sender;
        UriToPrint[NFTcount] = _uri;
        
        emit NFTMinted(msg.sender, NFTcount, _amount, block.timestamp);
        NFTcount++;

        return true;
    }

    /**
     * @dev Setter for new URI. It needs the agreement of the contract Owner & NFT Creator.
     * @param _NFTCollection: NFT Collection Identifier.
     * @param _newURI: New URI we want to update for the NFT Collection ID.
     */
    function updateURI(uint _NFTCollection, string memory _newURI) public returns(bool) {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *      Can only be called by the current owner.
     * @param newOwner: New Owner address we want to set.
     */
    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        return true;
    }

    /**
     * @dev Setter for the Minting fee the creator needs to pay per collection
     * @param _newMintingFee: New Fee to set.
     */
    function updateMintFee(uint _newMintingFee) public onlyOwner returns(bool){
        mintingFee = _newMintingFee;
        return true;
    }

}
    // THINGS TO ADD: 
    // DOES IT NEED INTERFACE TO INTERACT WITH THE CONTRACT???
    // PAY A FEE IF PER COLLECTION OR PER AMOUNT NFTs CREATED FOR THE COLLECTION???

    /**
     * @dev 
     * @param   
     */
