import { BigNumber, BigNumberish, Bytes, BytesLike, Signer, utils } from "ethers";

export class OwnerSignature {

    public static async sign(
        ownerSigner: Signer,
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        tokenId: BigNumberish, requestNonce: BigNumberish
    ): Promise<BytesLike> {
        const message: Bytes = utils.concat([
            utils.toUtf8Bytes("RequestBridge"),
            fromTokenAddr,
            fromBridgeAddr,
            toTokenAddr,
            toBridgeAddr,
            utils.zeroPad(BigNumber.from(tokenId).toHexString(), 32),
            utils.zeroPad(BigNumber.from(requestNonce).toHexString(), 32)
        ]);

        const rawSignature: string = await ownerSigner.signMessage(message);
        const compactSignature: string = utils.splitSignature(rawSignature).compact;
        return compactSignature;
    }

    public static async verify(
        ownerAddr: string,
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        tokenId: BigNumberish, requestNonce: BigNumberish,
        signature: BytesLike
    ): Promise<boolean> {
        const message: Bytes = utils.concat([
            utils.toUtf8Bytes("RequestBridge"),
            fromTokenAddr,
            fromBridgeAddr,
            toTokenAddr,
            toBridgeAddr,
            utils.zeroPad(BigNumber.from(tokenId).toHexString(), 32),
            utils.zeroPad(BigNumber.from(requestNonce).toHexString(), 32)
        ]);

        return utils.verifyMessage(message, signature) === ownerAddr;
    }
}
