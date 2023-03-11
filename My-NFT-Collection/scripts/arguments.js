const hre = require("hardhat");

const ethers = hre.ethers;

const MTK = "0x0dcbaE7A8296E1C742EEd5a3402c3e9A71963964";
const USDT = "0x5bA3e6C92e68D388FA991FC4d39048E19682CAed";
const DAI = "0xDD88Edeac0703603b56c320008e6e00535285972";

const tokenAddress = [MTK, USDT, DAI];
const nftMintingCosts = [
  ethers.utils.parseEther("1"),
  ethers.utils.parseEther("2"),
  ethers.utils.parseEther("3"),
];

module.exports = [tokenAddress, nftMintingCosts];
