const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NanoStore", function () {
  async function deployment() {
    const signers = await ethers.getSigners();
    const NanoStore = await ethers.getContractFactory("NanoStore");
    const nanoStore = await NanoStore.deploy("https://BaseURI/");
    await nanoStore.deployed();

    return { nanoStore, signers };
  }

  describe("Deployment", async function () {
    it("Deploy & Check the NanoStore ownership", async function () {
      const { nanoStore, signers } = await loadFixture(deployment);

      expect(await nanoStore.nanoStore()).to.equal(signers[0].address);

      console.log(
        `- NanoStore contract deployed successfully to: ${nanoStore.address}`
      );
      console.log(`- NanoStore owner is: ${signers[0].address}`);
      console.log("---------------------------------------");
    });
    it("Change ownership", async function () {
      const { nanoStore, signers } = await loadFixture(deployment);

      await expect(
        nanoStore.connect(signers[1]).transferOwnership(signers[2].address)
      ).to.be.reverted;

      await nanoStore.transferOwnership(signers[1].address);

      expect(await nanoStore.nanoStore()).to.equal(signers[1].address);
      console.log(
        `\n✅ Contract Ownership transferred to: ${signers[1].address}`
      );
      console.log("🛑 Reverted if called from not Owner");
    });

    it("Update minting Fee", async function () {
      const { nanoStore, signers } = await loadFixture(deployment);

      const weiValue = "20000000000000000"; // Equal to 0.02 Ethers
      const ethersValue = await ethers.utils.formatEther(weiValue);

      await expect(nanoStore.connect(signers[1]).updateMintFee(weiValue)).to.be
        .reverted;

      await nanoStore.updateMintFee(weiValue);
      expect(await nanoStore.mintingFee()).to.equal(weiValue);

      console.log(
        `\n✅ Minting Fee updated to: ${weiValue} Wei | ${ethersValue} Ether`
      );
      console.log("🛑 Reverted if called from not Owner");
      console.log("---------------------------------------");
    });

    it("Send minting fee, mint NFT Collection & Withdraw Fees stored in the contract", async function () {
      const { nanoStore, signers } = await loadFixture(deployment);
      const weiValue = "20000000000000000"; // Equal to 0.02 Ethers
      const valueEthers = ethers.utils.formatEther(weiValue);

      // Update Minting fee
      await nanoStore.updateMintFee(weiValue);
      expect(await nanoStore.mintingFee()).to.equal(weiValue);
      console.log("`\n✅ Minting fee updated");

      // Mint NFTs & pay fee
      await nanoStore.mintNFT("10", "<CollectionURITest1>", {
        value: weiValue,
      });
      console.log("✅ 10 NFTs has been minted & minting fee paid");

      // revert if not paid enough MintFee
      await expect(
        nanoStore.mintNFT("10", "Collection fail", {
          value: "10000000000000000",
        })
      ).to.be.reverted;

      console.log("🛑 Reverted if Creator pays less than mintFee");

      const valueTransaction = await ethers.provider.getBalance(
        nanoStore.address
      );

      console.log(
        `- After minting NanoStore holds: ${valueTransaction} Wei | ${valueEthers} Ether`
      );
      const balanceOwnerBeforeTransfer = await ethers.provider.getBalance(
        signers[0].address
      );

      // Withdrawn funds to Owner´s address.
      await nanoStore.withdrawnFunds(valueTransaction, signers[0].address);

      const balanceOwnerAfterTransfer = await ethers.provider.getBalance(
        signers[0].address
      );

      expect(balanceOwnerAfterTransfer).to.be.greaterThan(
        balanceOwnerBeforeTransfer
      );
      console.log(
        `\nFees transferred from NanoStore contract to Owner's address`
      );
      console.log(`- Balance before transfer: ${balanceOwnerBeforeTransfer}`);
      console.log(`- Balance after transfer:  ${balanceOwnerAfterTransfer}`);
      console.log(
        `The Owner now has extra ${
          balanceOwnerAfterTransfer - balanceOwnerBeforeTransfer
        } Weis`
      );
      console.log("---------------------------------------");
    });

    it("Set a 3D Store as elegible", async () => {
      // function store3DElegible(address _printStore) public onlyOwner returns(bool){
      const { nanoStore, signers } = await loadFixture(deployment);

      await expect(
        nanoStore.connect(signers[2]).store3DElegible(signers[1].address)
      ).to.be.reverted;

      await nanoStore.store3DElegible(signers[1].address);
      expect(await nanoStore.isStore3D(signers[1].address)).to.be.true;
      console.log(
        `\n✅ ${signers[1].address}has been set as elegible 3D Store`
      );
      console.log("🛑 Reverted if called from not Owner");
      console.log("---------------------------------------");
    });

    it("Update Base URI, check Base URI + Token URI & Mint NFT", async () => {
      // function updateBaseURI(string memory _baseURI) public onlyOwner returns(bool){

      const { nanoStore, signers } = await loadFixture(deployment);
      const newBaseURI = "https://NewBaseURIUpdated/";

      // Update BASE URI
      await nanoStore.updateBaseURI(newBaseURI);

      await expect(nanoStore.uri(0)).to.be.reverted;
      await expect(nanoStore.uri(10)).to.be.reverted;
      await expect(nanoStore.connect(signers[1]).updateBaseURI("ShouldFail")).to
        .be.reverted;

      console.log("\n🛑 Reverted if updating URI from not Owner");
      console.log(
        `🛑 Reverted if check URI of collection "0" or URI of not yet created collection`
      );

      // Mint NFTs, Creator is Signer 4
      await nanoStore.connect(signers[4]).mintNFT(5, "uriToken");
      console.log(`✅ Base URI Updated`);
      console.log(
        `BASE URI + TOKEN URI of Collection 1 is: ${await nanoStore.uri(1)}`
      );

      // Total supply of NFTs created
      const NFTSupply = await nanoStore.nFTsMinted(1);
      console.log(
        `✅ NFT ID 1 Collection created with a supply of ${NFTSupply} NFTs`
      );

      // Check the NFT Collection is matched with the creator when checking creator
      expect(await nanoStore.checkCreator(1)).to.equal(signers[4].address);
      console.log(`✅ NFT ID Collection assigned to creator address`);

      // Check the remaining supply to burn has to be equal to total supply minted by creator
      expect(await nanoStore.nFTsRemainingBurn(1)).to.equal(NFTSupply);
      console.log(`✅ Total supply still remaining to be burned by Owner`);

      // Check the creator has the total supply minted
      expect(await nanoStore.balanceOf(signers[4].address, 1)).to.equal(
        NFTSupply
      );
      console.log(`✅ Total supply assigned to creator`);

      expect(await nanoStore.uri(1)).to.equal(
        "https://NewBaseURIUpdated/uriToken"
      );
      console.log(`✅ URI for Collection 1 is: ${await nanoStore.uri(1)}`);
      console.log("---------------------------------------");
    });

    it("Mint 4 collections with different creator", async () => {
      const { nanoStore, signers } = await loadFixture(deployment);

      // Mint 3 NFTs collections
      await nanoStore.connect(signers[1]).mintNFT(5, "uriToken1");
      await nanoStore.connect(signers[2]).mintNFT(5, "uriToken2");
      await nanoStore.connect(signers[1]).mintNFT(5, "uriToken3");
      await nanoStore.connect(signers[1]).mintNFT(5, "uriToken4");

      const collectionsSigner1 = [];
      const collectionsSigner2 = [];

      for (let i = 0; i < 3; i++) {
        collectionsSigner1.push(
          await nanoStore.collectionsPerAddress(signers[1].address, [i])
        );
      }
      collectionsSigner2.push(
        await nanoStore.collectionsPerAddress(signers[2].address, [0])
      );

      expect(3).to.equal(collectionsSigner1.length);
      expect(1).to.equal(collectionsSigner2.length);

      console.log(
        `\n✅ Signer1 has created the next collections: ${collectionsSigner1} & the collection points to him as Creator`
      );
      console.log(
        `✅ Signer2 has created the next collections: ${collectionsSigner2} & the collection points to him as Creator`
      );
      console.log("---------------------------------------");
    });

    it("Create collection & Request to change URI", async () => {
      const { nanoStore, signers } = await loadFixture(deployment);

      // Mint NFT collection
      await nanoStore.connect(signers[1]).mintNFT(5, "uriToken1");

      // Request update Token URI from Creator
      await nanoStore.connect(signers[1]).updateURI(1, "NewUriToken1");
      console.log(`\n✅Creator requested to updated URI. 1st Request`);
      console.log(
        `- URI not updated for collection 1 after Creator request (1st approval): ${await nanoStore.uri(
          1
        )}`
      );

      // Revert!
      await expect(nanoStore.connect(signers[1]).updateURI(1, "NewUriToken1"))
        .to.be.reverted;
      console.log("🛑 Reverted if creator or Owner sends 2 requests");

      await expect(nanoStore.connect(signers[2]).updateURI(1, "NewUriToken1"))
        .to.be.reverted;
      console.log("🛑 Reverted if trying to update from not Owner or Creator");

      await expect(nanoStore.connect(signers[2]).updateURI(2, "NewUriToken2"))
        .to.be.reverted;
      console.log("🛑 Reverted if trying to update not created Collection");

      // Request update token URI from NanoStore Owner
      await nanoStore.updateURI(1, "NewUriToken1");
      console.log(`✅ Owner requested to updated URI. 2nd Request`);
      console.log(
        `- URI updated for collection 1 after Owner & Creator request (2nd approval): ${await nanoStore.uri(
          1
        )}`
      );
      console.log("---------------------------------------");
    });

    it("Whole process: Set 3D print store, Mint NFT Collection, send to a new user & send to print", async () => {
      const { nanoStore, signers } = await loadFixture(deployment);

      // Set 3D Print Store as elegible (Signers 10)
      await nanoStore.store3DElegible(signers[10].address);
      expect(await nanoStore.isStore3D(signers[10].address)).to.be.true;
      console.log(`\n✅ Signer10 has been set as elegible 3D Store`);

      // Mint many NFT Collections and check how the last one behaves
      for (let i = 0; i < 10; i++) {
        await nanoStore.connect(signers[1]).mintNFT(1, "testSginer1");
      }
      console.log("\n✅ 10 NFT collections created by Signer1");
      for (let i = 0; i < 20; i++) {
        await nanoStore.connect(signers[2]).mintNFT(1, "testSigner2");
      }
      console.log("✅ 20 NFT collections created by Signer2");

      await nanoStore.connect(signers[1]).mintNFT(50, "ZapatillasNike");
      expect(await nanoStore.nFTsMinted(31)).to.equal(50);
      const NFTsCreated = await nanoStore.nFTsMinted(31);
      console.log(
        `✅ Last minting by Signer1 has created an NFT Collection of ${NFTsCreated} NFTs`
      );

      // Transfer 20 NFTs (Last NFT collection minted ("31") from Signers1 to new Owner
      await nanoStore
        .connect(signers[1])
        .safeTransferFrom(signers[1].address, signers[2].address, 31, 20, "0x");
      expect(await nanoStore.balanceOf(signers[1].address, 31)).to.equal(30);

      const NFTBalanceAfterTransfer = await nanoStore.balanceOf(
        signers[2].address,
        31
      );

      console.log(
        `\n✅ Signer1 has transferred ${NFTBalanceAfterTransfer} NFTs of the collection 31 to Signer2`
      );

      // Print/Burn 10 NFTs in 3D Store from collection 31
      const ether = "1000000000000000000";
      await nanoStore
        .connect(signers[2])
        .printNFT(31, 10, 1, ether, signers[10].address, { value: ether });

      console.log("\n✅ 10 NFTs burned from the collection 31");
      const NFTsRemainingToBurn = await nanoStore.nFTsRemainingBurn(31);
      expect(NFTsRemainingToBurn).to.equal(40);
      console.log(
        `- There are ${NFTsRemainingToBurn} remaining to burn from the NFT collection 31 with a total of ${NFTsCreated}`
      );

      const NFTsTotalSupply = await nanoStore.balanceOf(signers[2].address, 31);
      expect(NFTsTotalSupply).to.equal(10);
      console.log(
        `- After Burning the total balance of NFT Collection 31 assigned to Signer2 is: ${NFTsTotalSupply}`
      );

      // NFTs minted should be equal as 50
      const NFTsMintedAfterBurning = await nanoStore.nFTsMinted(31);
      expect(NFTsCreated).to.equal(NFTsMintedAfterBurning);
      console.log(
        `- After Burning the total NFTs minted keeps being: ${NFTsMintedAfterBurning}`
      );

      // Confirm the signers[10] (3D Store selected) returns true after burning
      expect(
        await nanoStore.connect(signers[10]).checkStorePermission(31)
      ).to.equal(true);
      console.log(
        `\n✅ The 3D Store selected for printing NFT collection 31 is true`
      );
      await expect(nanoStore.connect(signers[1]).checkStorePermission(31)).to.be
        .reverted;
      console.log(
        `🛑 Reverted if checking from NOT 3D Store selected for printing NFT collection 31`
      );
      await expect(nanoStore.connect(signers[1]).checkStorePermission(31)).to.be
        .reverted;
      console.log(
        `🛑 Reverted if checking from selected 3D store for collection 31, for a different NFT Collection`
      );
      console.log("---------------------------------------");
    });

    it("Transfer NFTs (same collection)", async () => {
      const { nanoStore, signers } = await loadFixture(deployment);

      // Mint 1 NFTs collection
      await nanoStore.connect(signers[2]).mintNFT(30, "TokenURI1");
      console.log(`\n✅ Signer 2 has minted 30 NFTs (Collection ID 1)`);

      // Transfer from signer2 (NFT Owner) to signer1 (Caller Signer2)
      await nanoStore
        .connect(signers[2])
        .safeTransferFrom(signers[2].address, signers[1].address, 1, 10, "0x");
      console.log("✅ Signer2 has sent 10 NFTs (collection ID 1) to Signer1");

      // Transfer from signer2 to signer1 (Caller signer1) | It should revert as caller is not owner & doesn´t have permissions
      await expect(
        nanoStore.safeTransferFrom(
          signers[2].address,
          signers[1].address,
          1,
          10,
          "0x"
        )
      ).to.be.reverted;
      console.log(
        "\n🛑 Reverted if calling from signer1 to transfer NFTS assigned to signer2 & signer1 does not have permissions"
      );

      // Set approval for signer1 to transfer signer2 NFTs to signer3
      // (Requirement for MARKETPLACES TO MANAGE NFTs, signer1 would be the marketplace)
      await nanoStore
        .connect(signers[2])
        .setApprovalForAll(signers[1].address, true);
      console.log("\n✅Signer2 has approved Signer1 to manage all his NFTs");

      await nanoStore
        .connect(signers[1])
        .safeTransferFrom(signers[2].address, signers[3].address, 1, 10, "0x");
      console.log(
        "✅Signer1 has transferred 10 NFTs (Collection 1) from signer2 to signer3"
      );

      const balanceSigner3 = await nanoStore.balanceOf(signers[3].address, 1);
      expect(balanceSigner3).to.equal(10);
      console.log(
        `- Now signer3 has a total balance of ${balanceSigner3} NFTs (Collection 1)`
      );

      console.log("---------------------------------------");
    });
    it("Transfer different NFTs collections in once transaction using safeBatchTransferFrom()", async () => {
      const { nanoStore, signers } = await loadFixture(deployment);

      // Mint 2 NFTs collection
      await nanoStore.connect(signers[2]).mintNFT(20, "TokenURI1");
      await nanoStore.connect(signers[2]).mintNFT(20, "TokenURI2");
      console.log(
        `\n✅ Signer 2 has minted 20 NFTs (Collection ID 1) & 20 NFTs (Collection ID 2)`
      );

      //Transfer 2 Collections of NFTs (1 & 2) from signer2 to signer3
      await nanoStore
        .connect(signers[2])
        .safeBatchTransferFrom(
          signers[2].address,
          signers[3].address,
          [1, 2],
          [10, 10],
          "0x"
        );
      console.log(
        "\n✅ Signer2 has transferred 20 NFTs (10 of Collection 1 & 10 of Collection 2) to signer3"
      );

      // Transfer 2 NFTs Collections (1 & 2) from signer 2 to signer3 (Caller is signer1) || NOT APPROVED YET      await expect(
      await expect(
        nanoStore
          .connect(signers[1])
          .safeBatchTransferFrom(
            signers[2].address,
            signers[3].address,
            [1, 2],
            [10, 10],
            "0x"
          )
      ).to.be.reverted;
      console.log(
        "\n🛑 Reverted if calling from signer1 to transfer NFTS assigned to signer2 & signer1 does not have permissions"
      );

      // Approve signer1 to transfer NFTs from signer2 to signer3
      await nanoStore
        .connect(signers[2])
        .setApprovalForAll(signers[1].address, true);

      console.log("✅ Signer2 has approved Signer1 to manage his NFTs");

      // Transfer 2 NFTs Collections (1 & 2) from signer 2 to signer3 (Caller is signer1)
      await nanoStore
        .connect(signers[1])
        .safeBatchTransferFrom(
          signers[2].address,
          signers[3].address,
          [1, 2],
          [10, 10],
          "0x"
        );

      console.log(
        "\n✅ Signer1 has transferred 20 NFTs (10 of Collection 1 & 10 of Collection 2) from signer2 to signer3"
      );

      // Signer2 balance should equal to 0 after transfer
      const balanceSigner2ID1 = await nanoStore.balanceOf(
        signers[2].address,
        1
      );
      const balanceSigner2ID2 = await nanoStore.balanceOf(
        signers[2].address,
        2
      );

      expect(balanceSigner2ID1).to.equal(0);
      expect(balanceSigner2ID2).to.equal(0);

      // Signer3 balance should equal to 20 per NFT collection after transfer
      const balanceSigner3ID1 = await nanoStore.balanceOf(
        signers[3].address,
        1
      );
      const balanceSigner3ID2 = await nanoStore.balanceOf(
        signers[3].address,
        2
      );
      expect(balanceSigner3ID1).to.equal(20);
      expect(balanceSigner3ID2).to.equal(20);
      console.log(
        `✅ Signer3 now owns ${balanceSigner3ID1} NFTs(ID 1) & ${balanceSigner3ID2} NFTs(ID 2)`
      );
      console.log(
        `✅ Signer2 now owns ${balanceSigner2ID1} NFTs(ID 1) & ${balanceSigner2ID2} NFTs(ID 2)`
      );

      console.log("---------------------------------------");
    });
  });
});
