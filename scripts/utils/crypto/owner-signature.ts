import { BigNumber, Bytes, BytesLike, Signer, utils } from "ethers";

export namespace OwnerSignature {
    export type MessageContainer = {
        fromChainId:    BigNumber;
        fromToken:      string;
        fromBridge:     string;
        toChainId:      BigNumber;
        toToken:        string;
        toBridge:       string;
        requestNonce:   BigNumber;
        tokenId:        BigNumber;
        authnChallenge: BytesLike;
    };
}

export class OwnerSignature {
    public static async sign(
        ownerSigner: Signer,
        messageContainer: OwnerSignature.MessageContainer 
    ): Promise<BytesLike> {
        const message: Bytes = this._toMessage(messageContainer);

        const rawSignature: string = await ownerSigner.signMessage(message);
        const compactSignature: string = utils.splitSignature(rawSignature).compact;
        return compactSignature;
    }

    public static verify(
        ownerAddr: string,
        messageContainer: OwnerSignature.MessageContainer,
        signature: BytesLike
    ): boolean {
        const message: Bytes = this._toMessage(messageContainer);

        return utils.verifyMessage(message, signature) === ownerAddr;
    }

    private static _toMessage(messageContainer: OwnerSignature.MessageContainer): Bytes {
        return utils.concat([
            utils.toUtf8Bytes("RequestBridge"),
            utils.zeroPad(messageContainer.fromChainId.toHexString(), 32),
            messageContainer.fromToken,
            messageContainer.fromBridge,
            utils.zeroPad(messageContainer.toChainId.toHexString(), 32),
            messageContainer.toToken,
            messageContainer.toBridge,
            utils.zeroPad(messageContainer.requestNonce.toHexString(), 32),
            utils.zeroPad(messageContainer.tokenId.toHexString(), 32),
            // authnChallenge's size is fixed but may be changed in the future so it needs to be hashed.
            utils.keccak256(messageContainer.authnChallenge)
        ]);
    }
}
