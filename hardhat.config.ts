import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from 'dotenv';
dotenv.config();


const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },

  networks: {
    hardhat: {
    },
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY ??""]
    },
    sepolia: {
      url: `https://rpc.sepolia.org/`,
      accounts: [process.env.PRIVATE_KEY ?? ""],
      chainId: 11155111,
    },
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY
  },

};

export default config;
