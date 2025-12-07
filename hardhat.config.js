// Use CommonJS require statements
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv/config");

// Get variables from .env
const RPC_URL = process.env.CELO_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "NA";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.26",
  networks: {
    // Network name "celo"
    celo: {
      url: RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 42220, // Celo Mainnet Chain ID
    },
  },
  etherscan: {
    // API key configuration
    apiKey: {
      celo: ETHERSCAN_API_KEY,
    },
    // Custom chain definition for Celo
    customChains: [
      {
        network: "celo",
        chainId: 42220,
        urls: {
          apiURL: "https://api.etherscan.io/v2/api?chainid=42220",
          browserURL: "https://celoscan.io",
        },
      },
    ],
  },
};