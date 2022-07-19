import { BigNumberish, BytesLike } from "ethers";

export type BridgeRequestId = {
    readonly tokenOwner: string;
    readonly tokenId: BigNumberish;
    readonly requestNonce: BigNumberish;
}

export type BridgeRequest = {
    readonly id: BridgeRequestId;
    readonly ownerSignature: BytesLike;
}

export function buildBridgeRequest(
    tokenOwner: string,
    tokenId: BigNumberish, requestNonce: BigNumberish,
    ownerSignature: BytesLike
): BridgeRequest {
    return {
        id: {
            tokenOwner: tokenOwner,
            tokenId: tokenId,
            requestNonce: requestNonce
        },
        ownerSignature: ownerSignature
    };
}
