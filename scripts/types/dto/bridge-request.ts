import { BigNumber, BytesLike } from "ethers";

export class BridgeRequestId {
    readonly tokenOwner: string;
    readonly tokenId: BigNumber;
    readonly requestNonce: BigNumber;

    public constructor(
        tokenOwner: string,
        tokenId: BigNumber, requestNonce: BigNumber
    ) {
        this.tokenOwner = tokenOwner;
        this.tokenId = tokenId;
        this.requestNonce = requestNonce;
    }
}

export class BridgeRequest {
    public readonly id: BridgeRequestId;
    public readonly ownerSignature: BytesLike;
    
    public constructor(
        tokenOwner: string,
        tokenId: BigNumber, requestNonce: BigNumber,
        ownerSignature: BytesLike
    ) {
        this.id = {
            tokenOwner: tokenOwner,
            tokenId: tokenId,
            requestNonce: requestNonce
        };
        this.ownerSignature = ownerSignature;
    }
}
