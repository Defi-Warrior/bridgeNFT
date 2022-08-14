import { BigNumber } from "ethers";

export type NetworkInfo = {
    NAME: string,
    CHAIN_ID: number,
    RPC_URL: string,
    GAS_PRICE: BigNumber,
    [key: string]: any
};
