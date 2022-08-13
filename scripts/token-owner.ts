// Libraries
import { BigNumber, BytesLike, Signer } from "ethers";
import { ethers } from "hardhat";

// Typechain
import { IERC721, IFromBridge, IToBridge } from "../typechain-types";
import { TypedEventFilter, TypedListener } from "../typechain-types/common";
import { CommitEvent } from "../typechain-types/contracts/from/interfaces/IFromBridge";

// Project's modules
import OwnerConfig from "./types/config/owner-config";
import { OwnerSignature } from "./utils/crypto/owner-signature";
import { Validator } from "./validator";
import { BridgeContext, BridgeRequest, BridgeRequestId } from "./types/dto/bridge-request";

export class TokenOwner {
    public readonly address: string;
    private config: OwnerConfig;

    constructor(address: string, config: OwnerConfig) {
        this.address = address;
        this.config = config;
    }

    /* ********************************************************************************************** */

    public async approveForAll(fromOwnerSigner: Signer, fromTokenAddr: string, fromBridgeAddr: string) {
        const fromToken: IERC721 = await ethers.getContractAt("IERC721", fromTokenAddr, fromOwnerSigner);
        
        if (! await fromToken.isApprovedForAll(this.address, fromBridgeAddr)) {
            console.log("1a Not yet approved. Owner setApprovalForAll");
            const approveTx = await fromToken.setApprovalForAll(fromBridgeAddr, true);
            await approveTx.wait();
            console.log("1a Done");
        }
    }

    public async approve(fromOwnerSigner: Signer, fromTokenAddr: string, fromBridgeAddr: string, tokenId: BigNumber) {
        const fromToken: IERC721 = await ethers.getContractAt("IERC721", fromTokenAddr, fromOwnerSigner);

        if (!  (await fromToken.isApprovedForAll(this.address, fromBridgeAddr) ||
                await fromToken.getApproved(tokenId) === fromBridgeAddr) ) {
            fromToken.approve(fromBridgeAddr, tokenId);
        }
    }

    /* ********************************************************************************************** */

    public async getRequestNonce(fromOwnerSigner: Signer, fromBridgeAddr: string): Promise<BigNumber> {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", fromBridgeAddr, fromOwnerSigner);
        return fromBridge["getRequestNonce()"]();
    }

    public async getTokenUri(
        fromOwnerSigner: Signer,
        fromTokenAddr: string,
        fromBridgeAddr: string,
        tokenId: BigNumber
    ): Promise<BytesLike> {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", fromBridgeAddr, fromOwnerSigner);
        return fromBridge.getTokenUri(fromTokenAddr, tokenId);
    }

    /* ********************************************************************************************** */
    
    public async signRequest(
        fromOwnerSigner: Signer,
        request: BridgeRequest,
        authnChallenge: BytesLike
    ): Promise<BytesLike> {
        const { id: { context, requestNonce }, tokenId } = request;

        const ownerMessageContainer: OwnerSignature.MessageContainer = {
            fromChainId:    BigNumber.from(context.fromChainId),
            fromToken:      context.fromTokenAddr,
            fromBridge:     context.fromBridgeAddr,
            toChainId:      BigNumber.from(context.toChainId),
            toToken:        context.toTokenAddr,
            toBridge:       context.toBridgeAddr,
            requestNonce:   requestNonce,
            tokenId:        tokenId,
            authnChallenge: authnChallenge
        };
        
        return OwnerSignature.sign(fromOwnerSigner, ownerMessageContainer);
    }

    /* ********************************************************************************************** */

    public async bindListenerToCommitEvent(
        fromOwnerSigner: Signer,
        fromBridgeAddr: string,
        requestNonce: BigNumber,
        
        toOwnerSigner: Signer,
        validator: Validator,
        tokenUri: BytesLike
    ) {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", fromBridgeAddr, fromOwnerSigner);
        
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            null, null, null, null,
            this.address,
            requestNonce,
            null, null, null);
        
        
        const listener: TypedListener<CommitEvent> = async (
            fromTokenAddr,
            toChainId, toTokenAddr, toBridgeAddr,
            tokenOwnerAddr,
            requestNonce,
            tokenId,
            commitment,
            requestTimestamp,
            event
        ) => {
            console.log("7 Listen to commit success");
            // Ask validator for secret.
            const fromChainId: number = await fromOwnerSigner.getChainId();
            const requestId: BridgeRequestId = new BridgeRequestId(
                new BridgeContext(
                    fromChainId, fromTokenAddr, fromBridgeAddr,
                    toChainId.toNumber(), toTokenAddr, toBridgeAddr
                ),
                tokenOwnerAddr,
                requestNonce
            );

            console.log("8 Wait commit tx finalization");
            while (! await this._isCommitTxFinalized(fromOwnerSigner, requestId));
            console.log("8 Done");
            console.log("9 Validator revealSecret");
            const secret: BytesLike = await validator.revealSecret(requestId);
            console.log("9 Done");
            
            const origin: IToBridge.OriginStruct = {
                fromChainId: fromChainId,
                fromToken: fromTokenAddr,
                fromBridge: fromBridgeAddr
            };

            const oldTokenInfo: IToBridge.TokenInfoStruct = {
                tokenId: tokenId,
                tokenUri: tokenUri
            }

            console.log("10 Owner getValidatorSignature");
            const validatorSignature: BytesLike =
                await fromBridge["getValidatorSignature(uint256)"](requestNonce);
            console.log("10 Done");
            
            // Acquire new token.
            const toBridge: IToBridge = await ethers.getContractAt("IToBridge", toBridgeAddr, toOwnerSigner);
            console.log("11 Owner acquire");
            console.log(oldTokenInfo.tokenId);
            console.log(oldTokenInfo.tokenUri);
            const acquireTx = await toBridge.acquire(
                origin,
                this.address,
                oldTokenInfo,
                commitment, secret,
                requestTimestamp,
                validatorSignature,
                { gasLimit: 2000000, gasPrice: 5 * 10**10 }
            );
            const acquireTxReceipt = await acquireTx.wait();
            console.log("11 Done");

            // Test if bridge succeeded
            const eventArgs: any = acquireTxReceipt.events?.at(1)?.args;
            const newTokenId: BigNumber = eventArgs["newTokenId"];
            console.log("New token ID:");
            console.log(newTokenId);

            const toToken: IERC721 = await ethers.getContractAt("IERC721", toTokenAddr, toOwnerSigner);
            console.log("Bridge success:");
            console.log(await toToken.ownerOf(newTokenId) === tokenOwnerAddr);
        };
        
        fromBridge.once(filter, listener);
    }

    private async _isCommitTxFinalized(fromOwnerSigner: Signer, requestId: BridgeRequestId): Promise<boolean> {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", requestId.context.fromBridgeAddr, fromOwnerSigner);
        
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            null, null, null, null,
            requestId.tokenOwner,
            requestId.requestNonce,
            null, null, null);
        
        if (fromOwnerSigner.provider == undefined) {
            throw("Signer is not connected to any provider");
        }
        const newestBlock: number = await fromOwnerSigner.provider?.getBlockNumber();
        const events: CommitEvent[] = await fromBridge.queryFilter(filter, newestBlock - 10, newestBlock);

        if (events.length == 0) {
            throw("Commit transaction for this request does not exist or has not yet been mined")
        }
        const event: CommitEvent = events[events.length - 1];

        if (await fromOwnerSigner.provider.getBlockNumber() < event.blockNumber + this.config.NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION) {
            return false;
        }
        return true;
    }
}
