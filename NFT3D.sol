// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INFT3D{
    function printNFT(uint _nFTCollection, uint _amount, uint _size, uint _printingFee, string memory _material, address _printStore) external returns(bool);
    function mintNFT(uint _amount, string memory _uri) external payable returns(bool);
    function updateURI(uint _nfTCollection, string memory _newURI) external returns(bool);
}

contract NanoStore is IERC1155, ERC1155{

    address public nanoStore;
    // 1st NFT collection will be number 0 by default.
    uint private nFTcount;
    // Fee for minting a collection.
    uint public mintingFee;
    // Array with all the creators. It would be userful for Airdrops.
    address[] private creators;

    // NFTidCollection -> Creator
    mapping(uint => address) public checkCreator;
    // NFTidCollection -> NFTAmount (It will return the amount of NFTs created for a Colection) Example. 1 Shoes model, 10 available.
    mapping(uint => uint) public nFTsMinted;
    // NFTidCollection -> NFTsRemainingToBurn (It will return the amount of NFTs waiting to be burned)
    mapping(uint => uint) public nFTsRemainingBurn;
    // NFTidCollection -> Request URI -> owner or creator -> Accepted.
    mapping(uint => mapping(string => mapping(address => bool))) private changeURIRequest;
    // Creator address => array of his NFT Collections ID.
    mapping(address => uint[]) public collectionsPerAddres;
    // 3DPrintStore => NFTidCollection => If the Store was selected to print that NFTCollection
    mapping(address => mapping(uint => bool)) private storeSelected;
    // 3DPrintStore => If the address is a real Store;
    mapping(address => bool) public isStore3D;
    // NFT ID => NFT URI
    mapping(uint => string) public nftURI;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NFT3DBurned(address indexed owner, uint nFTCollection, uint size, string material, address printStore, uint burningTime);
    event NFTMinted(address indexed owner, uint nFTCollection, uint numberCollectionsCreator, uint amount, uint mintingTime);
    event URIUpdated(uint nFTCollection, string newURI, uint updateTime);
    event MintingFeeUpdated(uint newMintingFee, uint updateTime); 
    event NewCreator(address indexed creator, uint firstCreationTime);
    event FoundsWithdrawn(address indexed owner, uint ethersWithdrawn, uint withdrawnTime);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(nanoStore == msg.sender, "You`r not the owner");
        _;
    }

    constructor() ERC1155("https://cristianricharte6test.infura-ipfs.io/ipfs/"){
        nanoStore = msg.sender;
    }

    /**
     * @dev Minting function. It will set the URI, NFT Collection & amount of NFTs created.
     * @param _amount: Total amount of NFTs we want to mint. (Same NFT Collection)
     * @param _uri: Uri we want to set as the default URI when burned.
     */
    function mintNFT(uint _amount, bytes memory _uri) external payable returns(bool){
        require(msg.value >= mintingFee, "You need to pay Minting Fee");
        _mint(msg.sender, nFTcount, _amount, _uri);
        nFTsMinted[nFTcount] = _amount;
        nFTsRemainingBurn[nFTcount] = _amount;
        checkCreator[nFTcount] = msg.sender;
        collectionsPerAddres[msg.sender].push(nFTcount);

        for(uint i; i < creators.length; i++) {
            if(creators[i] != msg.sender) {  
                creators.push(msg.sender);
                emit NewCreator(msg.sender, block.timestamp);

            }
        }
        
        emit NFTMinted(msg.sender, nFTcount, collectionsPerAddres[msg.sender].length, _amount, block.timestamp);
        nFTcount++;

        return true;
    }

    /**
     * @dev Burning function to burn the token, pays the fee for the burining to the PrintStore3D & Creator.
     *      Also, it emits the URI to print. If we choose more than 1 NFT, it will print all of them under the same conditions.
            The print store 3D will have access to the password for this NFTCollection, after the function is compleated.
     * @param _nFTCollection: NFT Collection Identifier.
     * @param _amount: Total amount of NFTs we want to print. (Same NFT Collection)
     * @param _size: Desirable size for the NFT printed.
     * @param _printingFee: Printing Fee stablished by the Grams & Material + Creator fee.
     * @param _material: Desirable material for the NFT printed.
     * @param _printStore: Print store where we want to print the NFT.
     */
    function printNFT(uint _nFTCollection, uint _amount, uint _size, uint _printingFee, string memory _material, address _printStore) external payable returns(bool){
        require(msg.value == _printingFee, "Pay printingFee");
        require(isStore3D[_printStore], "Choose another 3DPrintStore");
        nFTsRemainingBurn[_nFTCollection] -= _amount;
        payable(checkCreator[_nFTCollection]).transfer((_printingFee / 100)*10); // 10% for creator.
        payable(_printStore).transfer((_printingFee / 100)*90); // 90% for PrintStore.
        _burn(msg.sender, _nFTCollection, _amount);
        storeSelected[_printStore][_nFTCollection] = true;

        emit NFT3DBurned(msg.sender, _nFTCollection, _size, _material, _printStore, block.timestamp);
        return true;
    }

    /**
     * @dev Toggle function to set Store 3D elegible to print or revoke elegibility to each address.
     * @param _printStore: PrintStore3D address.
     */
    function store3DElegible(address _printStore) public onlyOwner returns(bool){
        isStore3D[_printStore] =! isStore3D[_printStore];
        return(true);
    }


    /**
     * @dev Withdrawn function to extract from the contract the Fees paid for minting 3D NFts.
     * @param _amount: Amount in Ethers choosen to withdrawn.
     */
    function withdrawnFunds(uint _amount, address _to) public onlyOwner returns(bool) {
        payable(_to).transfer(_amount);
        emit FoundsWithdrawn(msg.sender, _amount, block.timestamp);
        return true;
    }

    /**
     * @dev Setter for new URI. It needs the agreement of the contract Owner & NFT Creator.
     * @param _nFTCollection: NFT Collection Identifier.
     * @param _newURI: New URI we want to update for the NFT Collection ID.
     */
    function updateURI(uint _nFTCollection, string memory _newURI) external returns(bool) {
        require(msg.sender == nanoStore || checkCreator[_nFTCollection] == msg.sender, "You can`t update URI");
        require(!changeURIRequest[_nFTCollection][_newURI][msg.sender], "You already approved");
        changeURIRequest[_nFTCollection][_newURI][msg.sender] = true;
        if(changeURIRequest[_nFTCollection][_newURI][nanoStore] && changeURIRequest[_nFTCollection][_newURI][checkCreator[_nFTCollection]]) {
            nftURI[_nFTCollection] = _newURI; 
        }

        emit URIUpdated(_nFTCollection, _newURI, block.timestamp);
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
        address oldOwner = nanoStore;
        nanoStore = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        return true;
    }

    /**
     * @dev Getter to check if the msg.sender has permissions to see the password to encrypt the URI.
     * @param _nFTCollection: NFT Collection Identifier.
     */
    function checkStorePermission(uint _nFTCollection) public view returns(bool){
        require(storeSelected[msg.sender][_nFTCollection], "You are not elegible to print this NFTID");
        return true;
    }

    /**
     * @dev Getter for the URI, following Opensea standars.
     * @param _nFTCollection: NFT Collection Identifier.
     */
    function uri(uint256 _nFTCollection) override public view returns (string memory) {
        return(nftURI[_nFTCollection]);
    }
}

/* Options:
    1. Encrypt in Solidity (NOT A SOLUTION): 
        - The input is stored in the Block Chain.

        // Example of encrypt in solidity. The input is stored in the blockchain
        function encryptURI(string memory uri) public pure returns (bytes32){
            bytes32 uriEncrypted = keccak256(abi.encodePacked(uri));
            return uriEncrypted;
        }

    2. URI Stored in NanoStore DataBase (PREFFERED): 
        - The URI is stored in our Data Base. 
        - The 3DStore needs to connect his wallet to our WebSite.
        - The Website will confirm if the address has permissions 
        to check the URI of a Specific NFTCollection through the Smart contract. If so, returns true.
        - The Website shows the URI to the 3DStore address.

    3. Encrypted with Asymmetric Keys in the BackEnd: 
        - The URI is encrypted with the public key of the 3Dstore chosen. 
        - The encrypted URI is added as a parameter for emitting the event.
        - Only the chosen 3Dstore can deencrypt the message (URI) with his private key.

    //////////////////////////////////////Base URI + PATH/////////////////////////////

    - Example of the URI stored in the Blockchain. The NFT Collection points to this: 
    "https://cristianricharte6test.infura-ipfs.io/ipfs/" + "QmPahtre1STYWgkvq34mVCQR3X4UGDbDyxEfypqzRd5wLK"
    https://cristianricharte6test.infura-ipfs.io/ipfs/QmPahtre1STYWgkvq34mVCQR3X4UGDbDyxEfypqzRd5wLK

    - Example of the URI for the STL (Should be encrypted and only accessed if conditions are met)
    "https://cristianricharte6test.infura-ipfs.io/ipfs/" + QmWVxr1iLc2yWX9aAvjoQKRFkNwEqU3zQKuR52sWvGiiZo
    https://cristianricharte6test.infura-ipfs.io/ipfs/QmWVxr1iLc2yWX9aAvjoQKRFkNwEqU3zQKuR52sWvGiiZo
    
*/ 
