// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFT3D is ERC1155, Ownable {

    event URI3DBurned(address indexed Owner, string URI, uint Size, uint BurningTime);
    event NFTMinted(address indexed Owner, uint NFTCollection, uint Amount, uint MintingTime);
    event URIUpdated(uint NFTCollection, string NewURI, uint UpdateTime);


    // 1st NFT collection will be number 0 by default.
    uint private NFTcount;

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

    constructor(string memory _uri) ERC1155(_uri){

    }

    // Burning function to burn the token and emit the URI to print.
    function printNFT(uint _NFTCollection, uint _amount, uint _size) public returns(bool){
        _burn(msg.sender, _NFTCollection, _amount);
        string memory _uri = UriToPrint[_NFTCollection];
        NFTsRemainingBurn[NFTcount] -= _amount;

        emit URI3DBurned(msg.sender, _uri, _size, block.timestamp);
        return true;
    }

    // Minting function. It will set the URI, NFT Collection & amount of NFTs created.
    function mintNFT(uint _amount, string memory _uri) public returns(bool){
        _mint(msg.sender, NFTcount, _amount, "");
        NFTsMinted[NFTcount] = _amount;
        NFTsRemainingBurn[NFTcount] = _amount;
        CheckCreator[NFTcount] = msg.sender;
        UriToPrint[NFTcount] = _uri;
        
        emit NFTMinted(msg.sender, NFTcount, _amount, block.timestamp);
        NFTcount++;

        return true;
    }

    // Setter for new URI. It needs the agreement of the contract Owner & NFT Creator.
    function updateURI(uint _NFTCollection, string memory _newURI) public returns(bool) {
        require(msg.sender == owner() || CheckCreator[_NFTCollection] == msg.sender, "You can`t update URI");
        require(!changeURIRequest[_NFTCollection][_newURI][msg.sender], "You already approved");
        changeURIRequest[_NFTCollection][_newURI][msg.sender] = true;
        if(changeURIRequest[_NFTCollection][_newURI][owner()] && changeURIRequest[_NFTCollection][_newURI][CheckCreator[_NFTCollection]]) {
            UriToPrint[_NFTCollection] = _newURI;
        }

        emit URIUpdated(_NFTCollection, _newURI, block.timestamp);
        return true;
    }


    // THINGS TO ADD: 
    // DOES IT NEED INTERFACE TO INTERACT WITH THE CONTRACT??
}
