import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import '@typechain/hardhat'
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

import ENV from "./env";

dotenvConfig({
    path: resolve(__dirname, ENV + ".env")
});

export default {
    solidity: "0.8.4",
    defaultNetwork: "localhost",
    networks: {
        hardhat: {},
        localhost: {
            url: "http://127.0.0.1:8545",
            accounts: [process.env.DEPLOYER_PRIVATE_KEY, process.env.VALIDATOR_PRIVATE_KEY],
        },
        bsctest: {
            url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
            accounts: [process.env.DEPLOYER_PRIVATE_KEY, process.env.VALIDATOR_PRIVATE_KEY],
        },
        bscmainnet: {
            url: "https://bsc-dataseed.binance.org/",
            accounts: [process.env.DEPLOYER_PRIVATE_KEY, process.env.VALIDATOR_PRIVATE_KEY],
        }
    }
};
