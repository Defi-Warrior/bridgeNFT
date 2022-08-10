export type FromBridgeInfo = {
    ADDRESS: string,
    VALIDATOR_REVOCABILITY: boolean
    [key: string]: any,
};

export type ToBridgeInfo = {
    ADDRESS: string,
    SUPPORT_CLAIM: boolean,
    VALIDATOR_REVOCABILITY: boolean,
    [key: string]: any,
};
