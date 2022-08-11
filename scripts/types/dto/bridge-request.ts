import { BigNumber, BytesLike } from "ethers";

export class BridgeContext {
    readonly fromChainId: number;
    readonly fromTokenAddr: string;
    readonly fromBridgeAddr: string;
    
    readonly toChainId: number;
    readonly toTokenAddr: string;
    readonly toBridgeAddr: string;

    public constructor(
        fromChainId: number, fromTokenAddr: string, fromBridgeAddr: string,
        toChainId: number, toTokenAddr: string, toBridgeAddr: string
    ) {
        this.fromChainId = fromChainId;
        this.fromTokenAddr = fromTokenAddr;
        this.fromBridgeAddr = fromBridgeAddr;

        this.toChainId = toChainId;
        this.toTokenAddr = toTokenAddr;
        this.toBridgeAddr = toBridgeAddr;
    }
};

export class BridgeRequestId {
    readonly context: BridgeContext;
    readonly tokenOwner: string;
    readonly requestNonce: BigNumber;

    public constructor(
        context: BridgeContext,
        tokenOwner: string,
        requestNonce: BigNumber
    ) {
        this.context = context;
        this.tokenOwner = tokenOwner;
        this.requestNonce = requestNonce;
    }
}

export class BridgeRequest {
    public readonly id: BridgeRequestId;
    public readonly tokenId: BigNumber;
    // public readonly challengeTimestamp: number;
    
    public constructor(
        requestId: BridgeRequestId,
        tokenId: BigNumber
    ) {
        this.id = requestId;
        this.tokenId = tokenId;
    }
}
