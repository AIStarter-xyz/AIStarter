import { HardhatUserConfig } from "hardhat/config"
import { NetworkUserConfig } from "hardhat/types"
// hardhat plugin
import "@nomiclabs/hardhat-ethers"
import "@nomicfoundation/hardhat-toolbox"

import { config as dotenvConfig } from "dotenv"
import { resolve } from "path"
import { loadTasks } from "./scripts/helpers/hardhatConfigHelpers"

dotenvConfig({ path: resolve(__dirname, "./.env") })

const taskFolder = ["tasks"]
loadTasks(taskFolder)

const chainIds = {
  goerli: 5,
  sepolia: 11155111,
  hardhat: 31337,
  mainnet: 1,
  "op-sepolia": 11155420,
  "polygon-cardona": 2442
}

// Ensure that we have all the environment variables we need.
const pk: string | undefined = process.env.PRIVATE_KEY
if (!pk) {
  throw new Error("Please set your pk in a .env file")
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY
if (!infuraApiKey) {
  throw new Error("Please set your INFURA_API_KEY in a .env file")
}

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string
  switch (chain) {
    case "op-sepolia":
      jsonRpcUrl = "https://sepolia.optimism.io"
      break
    case "polygon-cardona":
      jsonRpcUrl = "https://rpc.cardona.zkevm-rpc.com"
      break
    default:
      jsonRpcUrl = `https://${chain}.infura.io/v3/${infuraApiKey}`
  }
  return {
    accounts: [`0x${pk}`],
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  }
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
      chainId: chainIds.hardhat,
    },
    local: {
      url: "http://127.0.0.1:8545",
    },
    goerli: getChainConfig("goerli"),
    sepolia: getChainConfig("sepolia"),
    mainnet: getChainConfig("mainnet"),
    "op-sepolia": getChainConfig("op-sepolia"),
    "polygon-cardona": getChainConfig("polygon-cardona")
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
    ],
    settings: {
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yulDetails: true,
        },
      },
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      "op-sepolia": process.env.OPSEPOLIA_API_KEY || "",
      "polygon-cardona": process.env.POLYGON_API_KEY || ""
    },
    // https://docs.bscscan.com/v/opbnb-testnet/
    customChains: [{
      network: "op-sepolia",
      chainId: chainIds["op-sepolia"],
      urls: {
        apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
        browserURL: "https://sepolia-optimism.etherscan.io"
      }
    }, {
      network: "polygon-cardona",
      chainId: chainIds["polygon-cardona"],
      urls: {
        apiURL: "https://api-cardona-zkevm.polygonscan.com/api",
        browserURL: "https://cardona-zkevm.polygonscan.com"
      }
    }
    ],
  },

  gasReporter: {
    currency: "USD",
    gasPrice: 100,
    enabled: process.env.REPORT_GAS as string === "true",
    excludeContracts: [],
    src: "./contracts",
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
}

export default config