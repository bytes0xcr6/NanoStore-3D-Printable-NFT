require("@nomicfoundation/hardhat-toolbox");
// require("hardhat-gas-reporter");
require("dotenv").config();

ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;
MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY;
POLYGON_PRIVATE_KEY = process.env.POLYGON_PRIVATE_KEY;
POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    hardhat: {},
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/",
      chainId: 80001,
      gasPrice: 20000000000,
      accounts: [MUMBAI_PRIVATE_KEY],
    },
    // polygon: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   chainId: 56,
    //   gasPrice: 20000000000,
    //   accounts: [privateKey],
    // },
  },
  etherscan: {
    apiKey: POLYGONSCAN_API_KEY,
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: COINMARKETCAP_API_KEY,
    token: "MATIC",
  },
};
