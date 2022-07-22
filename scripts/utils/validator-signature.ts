import { BigNumber, Bytes, BytesLike, Signer, utils } from "ethers";

export class ValidatorSignature {

    public static async sign(
        validatorSigner: Signer,
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        tokenOwner: string, tokenId: BigNumber,
        tokenUri: string,
        commitment: BytesLike, requestTimestamp: BigNumber,
    ): Promise<BytesLike> {
        const message: Bytes = utils.concat([
            utils.toUtf8Bytes("Commit"),
            fromTokenAddr,
            fromBridgeAddr,
            toTokenAddr,
            toBridgeAddr,
            tokenOwner,
            utils.zeroPad(BigNumber.from(tokenId).toHexString(), 32),
            utils.id(tokenUri),
            commitment,
            utils.zeroPad(BigNumber.from(requestTimestamp).toHexString(), 32)
        ]);

        const rawSignature: string = await validatorSigner.signMessage(message);
        const compactSignature: string = utils.splitSignature(rawSignature).compact;
        return compactSignature;
    }

    public static async verify(
        validatorAddr: string,
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        tokenOwner: string, tokenId: BigNumber,
        tokenUri: string,
        commitment: BytesLike, requestTimestamp: BigNumber,
        signature: BytesLike
    ): Promise<boolean> {
        const message: Bytes = utils.concat([
            utils.toUtf8Bytes("Commit"),
            fromTokenAddr,
            fromBridgeAddr,
            toTokenAddr,
            toBridgeAddr,
            tokenOwner,
            utils.zeroPad(BigNumber.from(tokenId).toHexString(), 32),
            utils.id(tokenUri),
            commitment,
            utils.zeroPad(BigNumber.from(requestTimestamp).toHexString(), 32)
        ]);

        return utils.verifyMessage(message, signature) === validatorAddr;
    }
}
