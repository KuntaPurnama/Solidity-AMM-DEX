import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
import "hardhat-deploy";
dotenv.config();

const SEPOLIA_RPC_URL: string = process.env.SEPOLIA_RPC_URL || "LoL";
const SEPOLIA_PRIVATE_KEY: string = process.env.SEPOLIA_PRIVATE_KEY || "LoL";

const config: HardhatUserConfig = {
    solidity: {
        compilers: [{ version: "0.8.20" }]
    },
    networks: {
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: [SEPOLIA_PRIVATE_KEY],
            chainId: 11155111
        },
        localhost: {
            url: "http://127.0.0.1:8545/",
            //accounts : thanks hardhat,
            chainId: 31337
        },
        hardhat: {
            chainId: 31337,
            allowUnlimitedContractSize: true
        }
    },
    namedAccounts: {
        deployer: {
            default: 0
            //11155111: 0,
        },
        user: {
            default: 1
        }
    }
};

export default config;
