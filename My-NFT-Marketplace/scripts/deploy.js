// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const ethers = hre.ethers;

async function main() {
  const MTK = "0x0dcbaE7A8296E1C742EEd5a3402c3e9A71963964";
  const USDT = "0x5bA3e6C92e68D388FA991FC4d39048E19682CAed";
  const DAI = "0xDD88Edeac0703603b56c320008e6e00535285972";

  const tokenAddress = [MTK, USDT, DAI];
  const nftCollectionAddress = "0x1DF152BaeeE3C41f4341EA9CA3d5fCA7077Cc854";

  const MyNftMarketPlace = await ethers.getContractFactory("NftMarketPlace");
  const myNftMarketPlace = await MyNftMarketPlace.deploy(
    tokenAddress,
    nftCollectionAddress
  );
  await myNftMarketPlace.deployed();

  console.log(
    `MyNftCollection smart contract address ${myNftMarketPlace.address}`
  );
}
// MyNftCollection smart contract address 0x59f16111baf85AAe2774B97f6e38Fa296e1Ef175
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
