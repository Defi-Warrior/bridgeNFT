// Libraries
import { BigNumber, BytesLike, Signer, utils } from "ethers";
import { ethers } from "hardhat";
import sodium from "libsodium-wrappers";

// Typechain
import { TypedEventFilter } from "../typechain-types/common";
import { IERC721, IFromBridge } from "../typechain-types";
import { CommitEvent } from "../typechain-types/contracts/from/interfaces/IFromBridge";

// Project's modules
import ValidatorConfig from "./types/config/validator-config";
import { BridgeRequest, BridgeRequestId } from "./types/dto/bridge-request";
import { OwnerSignature } from "./utils/crypto/owner-signature";
import { ValidatorSignature } from "./utils/crypto/validator-signature";
import { getAddress, getSigner, Role } from "./utils/get-signer";
import { getNetworkInfo } from "../env/network";

export class Validator {
    public readonly address: string;
    private _config: ValidatorConfig;

    private _commitKey: Uint8Array;

    private constructor(config: ValidatorConfig) {
        this.address = getAddress(Role.VALIDATOR);
        this._config = config;
        this._commitKey = sodium.crypto_auth_keygen();
    }

    public static async instantiate(config: ValidatorConfig): Promise<Validator> {
        await sodium.ready;
        return new Validator(config);
    }

    private static _getSigner(chainId: number): Signer {
        return getSigner(Role.VALIDATOR, getNetworkInfo(chainId));
    }

    /* ********************************************************************************************** */

    public async processRequest(request: BridgeRequest, ownerSignature: BytesLike) {
        // Check all requirements.
        console.log("6a Verify request");
        await this._isValid(request, ownerSignature);
        console.log("6a Done");

        const { id: { context, tokenOwner, requestNonce }, tokenId } = request;

        const fromValidatorSigner: Signer = Validator._getSigner(context.fromChainId);
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", context.fromBridgeAddr, fromValidatorSigner);
 
        // Get token URI.
        console.log("6b Validator getTokenUri");
        const tokenUri: BytesLike = await fromBridge.getTokenUri(context.fromTokenAddr, tokenId);
        console.log("6b Done");

        // Generate commitment for this request.
        const commitment: BytesLike = this._generateCommitment(request.id);

        // Set requestTimestamp to current unix time.
        const requestTimestamp: BigNumber = Validator._unixTimeInSeconds();

        // Sign validator signature.
        const validatorSignature: BytesLike = await Validator._signValidatorSignature(
            fromValidatorSigner,
            request,
            tokenUri,
            commitment,
            requestTimestamp
        );

        // Send commit transaction.
        console.log("6c Validator commit");
        const commitTx = await fromBridge.commit(
            context.fromTokenAddr,
            {
                toChainId: context.toChainId,
                toToken: context.toTokenAddr,
                toBridge: context.toBridgeAddr
            },
            {
                tokenOwner: tokenOwner,
                requestNonce: requestNonce
            },
            tokenId,
            commitment,
            requestTimestamp,
            "0x00",
            ownerSignature,
            validatorSignature
        );
        await commitTx.wait();
        console.log("6c Done");
    }

    /* ********************************************************************************************** */

    private async _isValid(request: BridgeRequest, ownerSignature: BytesLike) {
        // Check signature and freshness.
        await this._verifyOwnerSignature(request, ownerSignature);

        // Parse request.
        const { id: { context, tokenOwner, requestNonce }, tokenId } = request;

        // Prepare contracts.
        const fromValidatorSigner: Signer = Validator._getSigner(context.fromChainId);
        const fromToken: IERC721 = await ethers.getContractAt("IERC721", context.fromTokenAddr, fromValidatorSigner);
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", context.fromBridgeAddr, fromValidatorSigner);

        // Check owner.
        if (await fromToken.ownerOf(tokenId) !== tokenOwner) {
            throw("Requester is not token owner");
        }

        // Check approval.
        if (!  (await fromToken.isApprovedForAll(tokenOwner, context.fromBridgeAddr) ||
                await fromToken.getApproved(tokenId) === context.fromBridgeAddr) ) {
            throw("FromBridge is not approved on token");
        }

        // Check request nonce.
        if (! (await fromBridge["getRequestNonce(address)"](tokenOwner)).eq(requestNonce) ) {
            throw("Invalid request nonce");
        }
    }

    private async _verifyOwnerSignature(request: BridgeRequest, ownerSignature: BytesLike) {
        const { id: { context, tokenOwner, requestNonce }, tokenId } = request;

        // Check timestamp.

        // Regenerate challenge.

        // Verify signature.
        const ownerMessageContainer: OwnerSignature.MessageContainer = {
            fromChainId:    BigNumber.from(context.fromChainId),
            fromToken:      context.fromTokenAddr,
            fromBridge:     context.fromBridgeAddr,
            toChainId:      BigNumber.from(context.toChainId),
            toToken:        context.toTokenAddr,
            toBridge:       context.toBridgeAddr,
            requestNonce:   requestNonce,
            tokenId:        tokenId,
            authnChallenge: "0x00"
        };
        if (! OwnerSignature.verify(tokenOwner, ownerMessageContainer, ownerSignature)) {
            throw("Invalid owner signature");
        }
    }

    /* ********************************************************************************************** */

    private _generateCommitment(requestId: BridgeRequestId): BytesLike {
        const secret: Uint8Array = sodium.crypto_auth(Validator._requestIdToString(requestId), this._commitKey);
        const commitment: BytesLike = utils.keccak256(secret);
        return commitment;
    }

    public async revealSecret(requestId: BridgeRequestId): Promise<BytesLike> {
        await this._checkCommitTxFinalized(requestId);
        const secret: Uint8Array = sodium.crypto_auth(Validator._requestIdToString(requestId), this._commitKey);
        return secret;
    }

    private static _requestIdToString(requestId: BridgeRequestId): string {
        const { context, tokenOwner, requestNonce } = requestId;
        return  "fromChainId:"  + utils.hexZeroPad(BigNumber.from(context.fromChainId).toHexString(), 8)    + "||" +
                "fromToken:"    + utils.hexZeroPad(context.fromTokenAddr, 20)                               + "||" +
                "fromBridge:"   + utils.hexZeroPad(context.fromBridgeAddr, 20)                              + "||" +
                "toChainId:"    + utils.hexZeroPad(BigNumber.from(context.toChainId).toHexString(), 8)      + "||" +
                "toToken:"      + utils.hexZeroPad(context.toTokenAddr, 20)                                 + "||" +
                "toBridge:"     + utils.hexZeroPad(context.toBridgeAddr, 20)                                + "||" +
                "tokenOwner:"   + utils.hexZeroPad(tokenOwner, 20)                                          + "||" +
                "requestNonce:" + utils.hexZeroPad(requestNonce.toHexString(), 32);
    }

    private async _checkCommitTxFinalized(requestId: BridgeRequestId) {
        const fromValidatorSigner: Signer = Validator._getSigner(requestId.context.fromChainId);
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", requestId.context.fromBridgeAddr, fromValidatorSigner);
        
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            null, null, null, null,
            requestId.tokenOwner,
            requestId.requestNonce,
            null, null, null);
        
        const events: CommitEvent[] = await fromBridge.queryFilter(filter);

        if (events.length == 0) {
            throw("Commit transaction for this request does not exist or has not yet been mined")
        }
        const event: CommitEvent = events[events.length - 1];

        if (fromValidatorSigner.provider == undefined) {
            throw("Signer is not connected to any provider");
        }
        if (await fromValidatorSigner.provider.getBlockNumber() < event.blockNumber + this._config.NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION) {
            throw("Commit transaction is not finalized yet");
        }
    }

    /* ********************************************************************************************** */

    private static _unixTimeInSeconds(): BigNumber {
        return BigNumber.from(Math.floor(Date.now() / 1000));
    }

    private static async _signValidatorSignature(
        validatorSigner: Signer,
        request: BridgeRequest,
        tokenUri: BytesLike,
        commitment: BytesLike,
        requestTimestamp: BigNumber
    ): Promise<BytesLike> {
        const { id: { context, tokenOwner }, tokenId } = request;
        const validatorMessageContainer: ValidatorSignature.MessageContainer = {
            fromChainId:        BigNumber.from(context.fromChainId),
            fromToken:          context.fromTokenAddr,
            fromBridge:         context.fromBridgeAddr,
            toChainId:          BigNumber.from(context.toChainId),
            toToken:            context.toTokenAddr,
            toBridge:           context.toBridgeAddr,
            tokenOwner:         tokenOwner,
            tokenId:            tokenId,
            tokenUri:           tokenUri,
            commitment:         commitment,
            requestTimestamp:   requestTimestamp
        };

        return ValidatorSignature.sign(validatorSigner, validatorMessageContainer);
    }
}
