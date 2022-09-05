// Libraries
import { BigNumber, BytesLike, Signer, utils } from "ethers";
import { ethers } from "hardhat";

// Typechain
import { IERC721, IFromBridge } from "../typechain-types";
import { TypedEventFilter, TypedListener } from "../typechain-types/common";
import { CommitEvent } from "../typechain-types/contracts/from/interfaces/IFromBridge";

// Project's modules
import OwnerConfig from "./types/config/owner-config";
import { OwnerSignature } from "./utils/crypto/owner-signature";
import { BridgeRequest, BridgeRequestId } from "./types/dto/bridge-request";
import { NetworkInfo } from "./types/dto/network-info";

export class TokenOwner {
    public readonly address: string;
    private config: OwnerConfig;

    constructor(address: string, config: OwnerConfig) {
        this.address = address;
        this.config = config;
    }

    /* ********************************************************************************************** */

    public async approveForAll(
        fromOwnerSigner: Signer,
        fromTokenAddr: string,
        fromBridgeAddr: string,

        fromNetwork: NetworkInfo) {
        const fromToken: IERC721 = await ethers.getContractAt("IERC721", fromTokenAddr, fromOwnerSigner);
        
        if (! await fromToken.isApprovedForAll(this.address, fromBridgeAddr)) {
            console.log("1a Not yet approved. Owner setApprovalForAll");
            const approveTx = await fromToken.setApprovalForAll(
                fromBridgeAddr,
                true,
                {
                    gasLimit: 100000,
                    gasPrice: fromNetwork.GAS_PRICE,
                });
            await approveTx.wait();
            console.log("1a Done");
        }
    }

    public async approve(
        fromOwnerSigner: Signer,
        fromTokenAddr: string,
        fromBridgeAddr: string,
        tokenId: BigNumber,

        fromNetwork: NetworkInfo) {
        const fromToken: IERC721 = await ethers.getContractAt("IERC721", fromTokenAddr, fromOwnerSigner);

        if (!  (await fromToken.isApprovedForAll(this.address, fromBridgeAddr) ||
                await fromToken.getApproved(tokenId) === fromBridgeAddr) ) {
            fromToken.approve(
                fromBridgeAddr,
                tokenId,
                {
                    gasLimit: 100000,
                    gasPrice: fromNetwork.GAS_PRICE
                });
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
    ): Promise<{ commitment: string, requestTimestamp: BigNumber }> {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", fromBridgeAddr, fromOwnerSigner);
        
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            null, null, null, null,
            this.address,
            requestNonce,
            null, null, null);
        
        return new Promise((res, rej) => {
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
                res({ commitment: commitment, requestTimestamp: requestTimestamp });
            };

            fromBridge.once(filter, listener);
        });
    }

    public async isCommitTxFinalized(fromOwnerSigner: Signer, requestId: BridgeRequestId): Promise<boolean> {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", requestId.context.fromBridgeAddr, fromOwnerSigner);
        
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            null, null, null, null,
            requestId.tokenOwner,
            requestId.requestNonce,
            null, null, null);
        
        if (fromOwnerSigner.provider == undefined) {
            throw("Signer is not connected to any provider");
        }
        const newestBlock: number = await fromOwnerSigner.provider.getBlockNumber();
        const events: CommitEvent[] = await fromBridge.queryFilter(filter, newestBlock - 20, newestBlock);

        if (events.length == 0) {
            throw("Commit transaction for this request does not exist or has not yet been mined")
        }
        const event: CommitEvent = events[events.length - 1];

        if (newestBlock < event.blockNumber + this.config.NUMBER_OF_BLOCK_CONFIRMATIONS) {
            console.log(`Mined block: ${event.blockNumber} - Newest block: ${newestBlock}`);
            return false;
        }
        return true;
    }
}
