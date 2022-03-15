// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const mint = async (contract, addr, description) => {
  let txn = await contract.mint(addr, description);
  await txn.wait();
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const MerkleNft = await hre.ethers.getContractFactory("MerkleNftV2");
  console.log("Start deploying...");
  const nft = await MerkleNft.deploy();

  await nft.deployed();
  console.log("Merkle nft v2 deployed to:", nft.address);  

  const [owner] = await hre.ethers.getSigners();

  console.log("Minting nfts");
  // Mint NFTs
  await mint(nft, owner.address, "nft 1");
  await mint(nft, owner.address, "nft 2");
  await mint(nft, owner.address, "nft 3");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
