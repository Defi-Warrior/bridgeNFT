// Types
import { BigNumber, BytesLike, Signer, utils } from "ethers";
import { TypedEventFilter } from "../typechain-types/common";
import { FromNFT, IFromBridge, IToBridge, ToNFT } from "../typechain-types";
import { CommitEvent } from "../typechain-types/contracts/interfaces/IFromBridge";

// Libraries
import { keccak256 } from "ethers/lib/utils";
import sodium from "libsodium-wrappers";

// Project's modules
import ValidatorConfig from "./types/config/validator-config";
import { BridgeRequest, BridgeRequestId } from "./types/dto/bridge-request";
import { OwnerSignature } from "./utils/crypto/owner-signature";
import { ValidatorSignature } from "./utils/crypto/validator-signature";

export class Validator {
    public readonly address: string;
    private signer: Signer;
    private config: ValidatorConfig;

    private commitKey: Uint8Array;

    private constructor(address: string, signer: Signer, config: ValidatorConfig) {
        this.address = address;
        this.signer = signer;
        this.config = config;
        this.commitKey = sodium.crypto_auth_keygen();
    }

    public static async instantiate(signer: Signer, config: ValidatorConfig): Promise<Validator> {
        await sodium.ready;
        return new Validator(await signer.getAddress(), signer, config);
    }

    public async processRequest(
        fromToken: FromNFT, fromBridge: IFromBridge,
        toToken: ToNFT, toBridge: IToBridge,
        request: BridgeRequest
    ) {
        // Check all requirements.
        await this._isValid(
            fromToken, fromBridge,
            toToken, toBridge,
            request);

        const { id: { tokenOwner, tokenId, requestNonce }, ownerSignature } = request;
        
        // Get token URI.
        const tokenUri: string = await fromToken.connect(this.signer).tokenURI(tokenId);

        // Generate commitment for this request.
        const commitment: BytesLike = this._generateCommitment(request.id);

        // Set requestTimestamp to current unix time.
        const requestTimestamp: BigNumber = this._unixTimeInSeconds();

        // Sign validator signature.
        const validatorSignature: BytesLike = await ValidatorSignature.sign(
            this.signer,
            fromToken.address, fromBridge.address,
            toToken.address, toBridge.address,
            tokenOwner,
            tokenId, tokenUri,
            commitment, requestTimestamp
        );

        // Send commit transaction.
        await fromBridge.connect(this.signer).commit(
            tokenOwner,
            tokenId, requestNonce,
            commitment, requestTimestamp,
            ownerSignature,
            validatorSignature
        );
    }

    private async _isValid(
        fromToken: FromNFT, fromBridge: IFromBridge,
        toToken: ToNFT, toBridge: IToBridge,
        request: BridgeRequest
    ) {
        // Parse request.
        const { id: { tokenOwner, tokenId, requestNonce }, ownerSignature } = request;
        
        // Check signature and freshness.
        await this._verifyOwnerSignature(
            tokenOwner,
            fromToken.address, fromBridge.address,
            toToken.address, toBridge.address,
            tokenId, requestNonce,
            ownerSignature
        );
        
        // Check owner.
        const fromToken_: FromNFT = fromToken.connect(this.signer);
        if (await fromToken_.ownerOf(tokenId) !== tokenOwner) {
            throw("Requester is not token owner");
        }

        // Check approval.
        if (!  (await fromToken_.isApprovedForAll(tokenOwner, fromBridge.address) ||
                await fromToken_.getApproved(tokenId) === fromBridge.address) ) {
            throw("FromBridge is not approved on token");
        }

        // Check request nonce.
        if (! (await fromBridge.connect(this.signer).getRequestNonce(tokenId)).eq(requestNonce) ) {
            throw("Invalid request nonce");
        }
    }

    private async _verifyOwnerSignature(
        tokenOwner: string,
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        tokenId: BigNumber, requestNonce: BigNumber,
        ownerSignature: BytesLike
    ) {
        // Check timestamp.

        // Regenerate challenge.

        // Verify signature.
        if (! await OwnerSignature.verify(
            tokenOwner,
            fromTokenAddr, fromBridgeAddr,
            toTokenAddr, toBridgeAddr,
            tokenId, requestNonce,
            ownerSignature
        ))
            throw("Invalid owner signature");
    }

    private _generateCommitment(requestId: BridgeRequestId): BytesLike {
        const secret: Uint8Array = sodium.crypto_auth(this._requestIdToString(requestId), this.commitKey);
        const commitment: BytesLike = keccak256(secret);
        return commitment;
    }

    public async revealSecret(fromBridge: IFromBridge, requestId: BridgeRequestId): Promise<BytesLike> {
        await this._checkCommitTxFinalized(fromBridge, requestId);
        const secret: Uint8Array = sodium.crypto_auth(this._requestIdToString(requestId), this.commitKey);
        return secret;
    }

    private async _checkCommitTxFinalized(fromBridge: IFromBridge, requestId: BridgeRequestId) {
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            requestId.tokenOwner,
            requestId.tokenId,
            requestId.requestNonce);
        
        const events: CommitEvent[] = await fromBridge.connect(this.signer).queryFilter(filter);

        if (events.length == 0) {
            throw("Commit transaction for this request does not exist or has not yet been mined")
        }
        const event: CommitEvent = events[events.length - 1];

        if (await this._newestBlockNumber() < event.blockNumber + this.config.NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION) {
            throw("Commit transaction is not finalized yet")
        }
    }

    private async _newestBlockNumber(): Promise<number> {
        const provider = this.signer.provider;
        if (provider === undefined) {
            throw("Signer is not connected to any provider");
        }
        return provider.getBlockNumber();
    }

    private _unixTimeInSeconds(): BigNumber {
        return BigNumber.from(Math.floor(Date.now() / 1000));
    }

    private _requestIdToString(requestId: BridgeRequestId): string {
        return  "tokenOwner:"   + utils.hexZeroPad(requestId.tokenOwner, 20)                    + "||" +
                "tokenId:"      + utils.hexZeroPad(requestId.tokenId.toHexString(), 32)         + "||" +
                "requestNonce:" + utils.hexZeroPad(requestId.requestNonce.toHexString(), 32);
    }
}
