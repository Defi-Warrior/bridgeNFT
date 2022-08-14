import { BigNumber } from "ethers";
import { NetworkInfo } from "../scripts/types/dto/network-info";

export const NETWORK = {
    LOCALHOST_8545: {
        NAME: "LOCALHOST_8545",
        CHAIN_ID: 31337,
        RPC_URL: "http://localhost:8545",
        GAS_PRICE: BigNumber.from("10" + "000000000") // 10 gwei
    },
    LOCALHOST_8546: {
        NAME: "LOCALHOST_8546",
        CHAIN_ID: 31338,
        RPC_URL: "http://localhost:8546",
        GAS_PRICE: BigNumber.from("10" + "000000000") // 10 gwei
    },
    BSC_MAIN: {
        NAME: "BSC_MAIN",
        CHAIN_ID: 56,
        RPC_URL: "https://bsc-dataseed.binance.org",
        GAS_PRICE: BigNumber.from("5" + "000000000") // 5 gwei
    },
    BSC_TEST: {
        NAME: "BSC_TEST",
        CHAIN_ID: 97,
        RPC_URL: "https://data-seed-prebsc-1-s1.binance.org:8545",
        GAS_PRICE: BigNumber.from("12" + "000000000") // 12 gwei
    },
    POLYGON_MAIN: {
        NAME: "POLYGON_MAIN",
        CHAIN_ID: 137,
        RPC_URL: "https://polygon-rpc.com",
        GAS_PRICE: BigNumber.from("40" + "000000000") // 40 gwei
    },
    POLYGON_TEST_MUMBAI: {
        NAME: "POLYGON_TEST_MUMBAI",
        CHAIN_ID: 80001,
        RPC_URL: "https://rpc-mumbai.maticvigil.com",
        GAS_PRICE: BigNumber.from("50" + "000000000") // 50 gwei
    }
};

export function getNetworkInfo(chainId: number): NetworkInfo {
    switch (chainId) {
        case 31337: {
            return NETWORK.LOCALHOST_8545;
        }
        case 31338: {
            return NETWORK.LOCALHOST_8546;
        }
        case 56: {
            return NETWORK.BSC_MAIN;
        }
        case 97: {
            return NETWORK.BSC_TEST;
        }
        case 137: {
            return NETWORK.POLYGON_MAIN;
        }
        case 80001: {
            return NETWORK.POLYGON_TEST_MUMBAI;
        }
        default: {
            throw("Network with chain ID " + chainId + " is not available");
        }
    }
}
