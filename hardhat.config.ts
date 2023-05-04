import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";



const PRIVATE_KEY =
  "529920105e2db45ee65119654b84cc4ac7c21292e8c2c425a95f3cb3a7c9411a";

const POLYGONSCAN_API_KEY = "A8GM6M48B2Z1DYP8FTT6W9JTA1M7SJS5T2";

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
      accounts: [PRIVATE_KEY]
    },
     sepolia: {
      url: `https://rpc.sepolia.org/`,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
    },
  },
  etherscan: {
    apiKey: POLYGONSCAN_API_KEY
  },
  
};

export default config;
