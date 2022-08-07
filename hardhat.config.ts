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
    solidity: {
        version: "0.8.15",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            "viaIR": false
        }
    }
};
