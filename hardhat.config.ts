import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import '@typechain/hardhat'
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

import ENV from "./env";
dotenvConfig({
    path: resolve(__dirname, "env", ENV, "secrets")
});

export default {
    solidity: "0.8.4"
};
