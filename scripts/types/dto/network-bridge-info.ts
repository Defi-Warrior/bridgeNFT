import { FromTokenInfo, ToTokenInfo } from "./token-info";
import { FromBridgeInfo } from "./bridge-info";

export type FromNetworkBridgeInfo = {
    CHAIN_NAME: string,
    TOKENS: {
        [tokenAddr: string]: FromTokenInfo
    },
    DYNAMIC_BURNING_FROMBRIDGE: FromBridgeInfo,
    DYNAMIC_HOLDING_FROMBRIDGE: FromBridgeInfo,
    [key: string]: any
};

export type ToNetworkBridgeInfo = {
    CHAIN_NAME: string,
    TOKENS: {
        [tokenAddr: string]: ToTokenInfo
    },
    [key: string]: any
};
