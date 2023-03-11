require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");

const { rpcUrl, privateKey, etherscanapikey } = process.env;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    bscTestnet: {
      url: rpcUrl,
      accounts: [privateKey],
      chainId: 97,
    },
  },
  etherscan: {
    apiKey: {
      bscTestnet: etherscanapikey,
    },
  },
};
