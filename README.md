# 👟 NanoStore 3D Printable NFT (Smart contract)

## Project Goal

Experience virtual items in the real world through AR and convert them into physical goods through 3D printing.

Design a online lifestyle products store

Allow designers to safely upload and sell their designs plus get the fair part of royalties thanks to the smart contract.

Allow consumers to browse unique designs from all over the world and buy them to have them produced on-demand. Products can be experienced in AR before buying.

Minimize the environmental impact of lifestyle e-commerce, by altering the value chain with 3D printing.

## Smart Contract address (Mumbai Testnet):

```
0x26478E66df15D9eB2E8fDc9267f0b6e8d2EDbc78
```

- <a href="https://mumbai.polygonscan.com/address/0x26478E66df15D9eB2E8fDc9267f0b6e8d2EDbc78">Mumbai testnet NanoStore contract</a>
- <a href="https://testnets.opensea.io/collection/unidentified-contract-wf5kiypgik">OpenSea Mumbai (NanoStore contract)</a>

## Contract tested through:

- Remix. ✅
- Slither (Static Analyzer). ✅
- Solhint (Advance Linter). ✅
- Compatibility with Marketplaces. ✅
- Unit tests. ✅
- Solidity coverage. ✅

# Smart contract Workflow

1. Deploy contract passing Base Uri.
2. Set Minting Fee & Set Burning Fee (This fees will be kept in NanoStore contract for Withdrawn)
3. Set 3D Printing Store whitelist addresses.
4. Creators can mint, transfer & list their NFTs in any marketplace.
5. NFT Holders can burn / send to print their NFTs. (This transaction will include a fee for Printing (for the 3D printing store), for Burning (for NanoStore) & royalties (for the creator), all these fees will be transferred automatically to the 3D Printing store, Creator address & NanoStore contract. Also to the Social organization in case it is set)
6. The smart contract owner can withdraw the funds from the contract.
7. Base URI can be updated by the owner.
8. Token URI can be updated but the creator and the contract owner must agree.

## URI Stored in NanoStore DataBase workflow:

        - Artist uploads img and info to create metadata. A script creates the JSON file &  uploads to IPFS & this URI is added when minting NFT Collection.
        - Artist uploads STL pointing to his NFT Collection. A script uploads it to IPFS.
        - The STL URI is stored in our Data Base. (NFT Collection ID -> STL URI).
        - Then the NFT is burned/sent to print. An Event will be emitted and the 3DStore will be aware of it.
        - The 3DStore needs to connect his wallet to our WebSite.
        - The Smart contract will confirm if the 3DStore has permissions to see the URI.
        - The Website shows the URI to the 3DStore address.


    - Example of the URI stored in the Blockchain. The NFT Collection points to this:
    "https://cristianricharte6test.infura-ipfs.io/ipfs/" + "QmPahtre1STYWgkvq34mVCQR3X4UGDbDyxEfypqzRd5wLK"
    https://cristianricharte6test.infura-ipfs.io/ipfs/QmPahtre1STYWgkvq34mVCQR3X4UGDbDyxEfypqzRd5wLK

    - Example of the URI for the STL (Should be stored in out dataBase and only accessed if conditions are met)
    "https://cristianricharte6test.infura-ipfs.io/ipfs/" + QmWVxr1iLc2yWX9aAvjoQKRFkNwEqU3zQKuR52sWvGiiZo
    https://cristianricharte6test.infura-ipfs.io/ipfs/QmWVxr1iLc2yWX9aAvjoQKRFkNwEqU3zQKuR52sWvGiiZo
