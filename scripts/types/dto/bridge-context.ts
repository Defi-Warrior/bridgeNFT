export type BridgeContext = {
    readonly fromTokenAddr: string,
    readonly fromBridgeAddr: string,
    readonly toTokenAddr: string,
    readonly toBridgeAddr: string
};

export default BridgeContext;
