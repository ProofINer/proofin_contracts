import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    hardhat: {}, // 로컬 네트워크
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    ganache: {
      url: "http://127.0.0.1:7545", // 가나슈 기본 포트
      accounts: (process.env.PRIVATE_KEY && process.env.PRIVATE_KEY.startsWith('0x')) ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 20000000000, // 20 gwei
      chainId: 1337 // 가나슈 기본 체인 ID
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: (process.env.PRIVATE_KEY && process.env.PRIVATE_KEY.startsWith('0x')) ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 20000000000, // 20 gwei
      chainId: 11155111
    },
    sonic: {
      url: process.env.SONIC_RPC_URL || "https://rpc.soniclabs.com",
      accounts: (process.env.PRIVATE_KEY && process.env.PRIVATE_KEY.startsWith('0x')) ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 1000000000, // 1 gwei (소닉은 가스비가 저렴)
      chainId: 146
    },
    base: {
      url: process.env.BASE_RPC_URL || "https://mainnet.base.org",
      accounts: (process.env.PRIVATE_KEY && process.env.PRIVATE_KEY.startsWith('0x')) ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 1000000000, // 1 gwei
      chainId: 8453
    },
    "base-sepolia": {
      url: process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org",
      accounts: (process.env.PRIVATE_KEY && process.env.PRIVATE_KEY.startsWith('0x')) ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 1000000000, // 1 gwei
      chainId: 84532
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      base: process.env.BASESCAN_API_KEY || "",
      "base-sepolia": process.env.BASESCAN_API_KEY || ""
      // Sonic은 아직 etherscan 지원 없음
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org"
        }
      },
      {
        network: "base-sepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org"
        }
      }
    ]
  }
};

export default config;
