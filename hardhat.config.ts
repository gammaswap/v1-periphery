import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomicfoundation/hardhat-foundry";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

require("hardhat-contract-sizer"); // "npx hardhat size-contracts" or "yarn run hardhat size-contracts"

dotenv.config();

// npx hardhat accounts
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "paris",
    },
  },
  networks: {
    arbitrumGoerli: {
      url: `https://arb-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_ARBITRUM_GOERLI_API_KEY}`,
      accounts: {
        mnemonic: process.env.ARBITRUM_GOERLI_MNEMONIC || "",
      },
      chainId: 421613,
    },
    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_ARBITRUM_SEPOLIA_API_KEY}`,
      accounts: {
        mnemonic: process.env.ARBITRUM_SEPOLIA_MNEMONIC || "",
      },
      chainId: 421614,
    },
    arbitrum: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_ARBITRUM_API_KEY}`,
      accounts: {
        mnemonic: process.env.ARBITRUM_MNEMONIC || "",
      },
      chainId: 42161,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
};

export default config;
