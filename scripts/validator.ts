// Types
import { BigNumberish, BytesLike, Signer } from "ethers";
import { FromNFT, IFromBridge, IToBridge, ToNFT } from "../typechain-types";

// Libraries
import { keccak256 } from "ethers/lib/utils";
import sodium from "libsodium-wrappers";

// Project's modules
import ValidatorConfig from "./types/config/validator-config";
import { BridgeRequest, BridgeRequestId } from "./types/dto/bridge-request";
import { OwnerSignature } from "./utils/owner-signature";
import { ValidatorSignature } from "./utils/validator-signature";

export class Validator {
    private config: ValidatorConfig;
    private signer: Signer;

    private secrets: Map<BridgeRequestId, BytesLike>;

    private constructor(config: ValidatorConfig, signer: Signer) {
        this.config = config;
        this.signer = signer;
        this.secrets = new Map<BridgeRequestId, BytesLike>();
    }

    public static async instantiate(config: ValidatorConfig, signer: Signer): Promise<Validator> {
        await sodium.ready;
        return new Validator(config, signer);
    }

    public async address(): Promise<string> {
        return this.signer.getAddress();
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
        fromToken.connect(this.signer);
        const tokenUri: string = await fromToken.tokenURI(tokenId);

        // Generate commitment for this request.
        const commitment: BytesLike = this._generateCommitment(request.id);

        // Set requestTimestamp to current unix time.
        const requestTimestamp: BigNumberish = this._unixTimeInSeconds();

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
        fromBridge.connect(this.signer);
        fromBridge.commit(
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
        fromToken.connect(this.signer);
        if (await fromToken.ownerOf(tokenId) !== tokenOwner) {
            throw("Requester is not token owner");
        }

        // Check approval.
        if (!  (await fromToken.isApprovedForAll(this.address(), fromBridge.address) ||
                await fromToken.getApproved(tokenId) === fromBridge.address) ) {
            throw("FromBridge is not approved on token");
        }

        // Check request nonce.
        fromBridge.connect(this.signer);
        if (await fromBridge.getRequestNonce(tokenId) !== requestNonce) {
            throw("Invalid request nonce");
        }
    }

    private async _verifyOwnerSignature(
        tokenOwner: string,
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        tokenId: BigNumberish, requestNonce: BigNumberish,
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
        const secret: BytesLike = sodium.randombytes_buf(256);
        const commitment: BytesLike = keccak256(secret);
        this.secrets.set(requestId, secret);
        return commitment;
    }

    private _unixTimeInSeconds(): number {
        return Math.floor(Date.now() / 1000);
    }
}
