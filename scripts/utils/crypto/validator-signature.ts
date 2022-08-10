import { BigNumber, Bytes, BytesLike, Signer, utils } from "ethers";

export namespace ValidatorSignature {
    export type MessageContainer = {
        fromChainId:        BigNumber;
        fromToken:          string;
        fromBridge:         string;
        toChainId:          BigNumber;
        toToken:            string;
        toBridge:           string;
        tokenOwner:         string;
        tokenId:            BigNumber;
        tokenUri:           BytesLike;
        commitment:         BytesLike;
        requestTimestamp:   BigNumber;
    };
}

export class ValidatorSignature {
    public static async sign(
        validatorSigner: Signer,
        messageContainer: ValidatorSignature.MessageContainer,
    ): Promise<BytesLike> {
        const message: Bytes = this._toMessage(messageContainer);

        const rawSignature: string = await validatorSigner.signMessage(message);
        const compactSignature: string = utils.splitSignature(rawSignature).compact;
        return compactSignature;
    }

    public static async verify(
        validatorAddr: string,
        messageContainer: ValidatorSignature.MessageContainer,
        signature: BytesLike
    ): Promise<boolean> {
        const message: Bytes = this._toMessage(messageContainer);

        return utils.verifyMessage(message, signature) === validatorAddr;
    }

    private static _toMessage(messageContainer: ValidatorSignature.MessageContainer): Bytes {
        return utils.concat([
            utils.toUtf8Bytes("Commit"),
            utils.zeroPad(messageContainer.fromChainId.toHexString(), 32),
            messageContainer.fromToken,
            messageContainer.fromBridge,
            utils.zeroPad(messageContainer.toChainId.toHexString(), 32),
            messageContainer.toToken,
            messageContainer.toBridge,
            messageContainer.tokenOwner,
            utils.zeroPad(messageContainer.tokenId.toHexString(), 32),
            // tokenUri's size is dynamic so it needs to be hashed.
            utils.keccak256(messageContainer.tokenUri),
            // commitment's size is fixed (32 bytes) so it does not need to be hashed.
            messageContainer.commitment,
            utils.zeroPad(messageContainer.requestTimestamp.toHexString(), 32)
        ]);
    }
}
