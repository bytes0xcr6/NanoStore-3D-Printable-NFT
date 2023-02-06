require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
// require("solidity-coverage");
require("dotenv").config();

ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;
PRIVATE_KEY = process.env.PRIVATE_KEY;
MUMBAI_KEY = process.env.MUMBAI_KEY;
POLYGON_KEY = process.env.POLYGON_KEY;

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
  // networks: {
  //   localhost: {
  //     url: "http://127.0.0.1:8545",
  //   },
  //   hardhat: {},
  //   testnet: {
  //     url: "https://data-seed-prebsc-1-s1.binance.org:8545",
  //     chainId: 97,
  //     gasPrice: 20000000000,
  //     accounts: [MUMBAI_KEY],
  //   },
  //   mainnet: {
  //     url: "https://bsc-dataseed.binance.org/",
  //     chainId: 56,
  //     gasPrice: 20000000000,
  //     accounts: [POLYGON_KEY],
  //   },
  // },
  gasReporter: {
    outputFile: "gas-report.txt",
    noColors: true,
    enabled: true,
    // currency: "USD",
    coinmarketcap: COINMARKETCAP_API_KEY,
    token: "MATIC",
  },
  allowUnlimitedContractSize: false,
};
