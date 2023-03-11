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
  const nftMintingCosts = [
    ethers.utils.parseEther("1"),
    ethers.utils.parseEther("2"),
    ethers.utils.parseEther("3"),
  ];

  const MyNftCollection = await ethers.getContractFactory("MyNftCollection");
  const myNftCollection = await MyNftCollection.deploy(
    tokenAddress,
    nftMintingCosts
  );
  await myNftCollection.deployed();

  console.log(
    `MyNftCollection smart contract address ${myNftCollection.address}`
  );
}
// MyNftCollection smart contract address 0x1DF152BaeeE3C41f4341EA9CA3d5fCA7077Cc854
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
