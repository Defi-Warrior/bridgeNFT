import { NetworkInfo } from "../scripts/types/dto/network-info";

export const NETWORK = {
    LOCALHOST_8545: {
        NAME: "LOCALHOST_8545",
        CHAIN_ID: 31337,
        RPC_URL: "http://localhost:8545"
    },
    LOCALHOST_8546: {
        NAME: "LOCALHOST_8546",
        CHAIN_ID: 31338,
        RPC_URL: "http://localhost:8546"
    },
    BSC_MAIN: {
        NAME: "BSC_MAIN",
        CHAIN_ID: 56,
        RPC_URL: "https://bsc-dataseed.binance.org"
    },
    BSC_TEST: {
        NAME: "BSC_TEST",
        CHAIN_ID: 97,
        RPC_URL: "https://data-seed-prebsc-1-s1.binance.org:8545"
    },
    POLYGON_MAIN: {
        NAME: "POLYGON_MAIN",
        CHAIN_ID: 137,
        RPC_URL: "https://polygon-rpc.com"
    },
    POLYGON_TEST_MUMBAI: {
        NAME: "POLYGON_TEST_MUMBAI",
        CHAIN_ID: 80001,
        RPC_URL: "https://rpc-mumbai.maticvigil.com"
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
