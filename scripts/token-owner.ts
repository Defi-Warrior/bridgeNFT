import { BigNumberish, BytesLike, Signer } from "ethers";
import { FromNFT, IFromBridge, IToBridge, ToNFT } from "../typechain-types";
import { TypedEventFilter, TypedListener } from "../typechain-types/common";
import { CommitEvent } from "../typechain-types/contracts/interfaces/IFromBridge";

import OwnerConfig from "./types/config/owner-config";
import { OwnerSignature } from "./utils/owner-signature";
import { Validator } from "./validator";
import { BridgeRequestId } from "./types/dto/bridge-request";

export class TokenOwner {
    private config: OwnerConfig;
    private signer: Signer;

    constructor(config: OwnerConfig, signer: Signer) {
        this.config = config;
        this.signer = signer;
    }

    public async address(): Promise<string> {
        return this.signer.getAddress();
    }

    public async approveForAll(fromToken: FromNFT, fromBridge: IFromBridge) {
        fromToken.connect(this.signer);
        if (! await fromToken.isApprovedForAll(this.address(), fromBridge.address)) {
            fromToken.setApprovalForAll(fromBridge.address, true);
        }
    }

    public async approve(fromToken: FromNFT, fromBridge: IFromBridge, tokenId: BigNumberish) {
        fromToken.connect(this.signer);
        if (!  (await fromToken.isApprovedForAll(this.address(), fromBridge.address) ||
                await fromToken.getApproved(tokenId) === fromBridge.address) ) {
            fromToken.approve(fromBridge.address, tokenId);
        }
    }

    public async getRequestNonce(fromBridge: IFromBridge, tokenId: BigNumberish): Promise<BigNumberish> {
        fromBridge.connect(this.signer);
        return fromBridge.getRequestNonce(tokenId);
    }
    
    public async signRequest(
        fromToken: FromNFT, fromBridge: IFromBridge,
        toToken: ToNFT, toBridge: IToBridge,
        tokenId: BigNumberish, requestNonce: BigNumberish
    ): Promise<BytesLike> {
        return OwnerSignature.sign(
            this.signer,
            fromToken.address, fromBridge.address,
            toToken.address, toBridge.address,
            tokenId, requestNonce
        );
    }

    public bindListenerToCommitEvent(
        fromToken: FromNFT, fromBridge: IFromBridge,
        toBridge: IToBridge,
        tokenId: BigNumberish, requestNonce: BigNumberish,
        validator: Validator
    ) {
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            this.address(),
            tokenId,
            requestNonce);
        
        const listener: TypedListener<CommitEvent> = async (
            tokenOwner,
            tokenId, requestNonce,
            commitment, requestTimestamp,
            validatorSignature,
            event
        ) => {
            fromToken.connect(this.signer);
            const tokenUri: string = await fromToken.tokenURI(tokenId);

            // Ask validator for secret.
            const requestid: BridgeRequestId = {
                tokenOwner: tokenOwner,
                tokenId: tokenId,
                requestNonce: requestNonce
            }
            while (! await this._isCommitTxFinalized(fromBridge, requestid));
            const secret: BytesLike = await validator.revealSecret(fromBridge, requestid);

            // Acquire new token.
            toBridge.acquire(
                this.address(),
                tokenId, tokenUri,
                commitment, secret,
                requestTimestamp,
                validatorSignature
            )
        };
        
        fromBridge.connect(this.signer);
        fromBridge.once(filter, listener);
    }

    private async _isCommitTxFinalized(fromBridge: IFromBridge, requestId: BridgeRequestId): Promise<boolean> {
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            requestId.tokenOwner,
            requestId.tokenId,
            requestId.requestNonce);
        
        fromBridge.connect(this.signer);
        const events: CommitEvent[] = await fromBridge.queryFilter(filter);

        if (events.length == 0) {
            throw("Commit transaction for this request does not exist or has not yet been mined")
        }
        const event: CommitEvent = events[events.length - 1];

        if (await this._newestBlockNumber() < event.blockNumber + this.config.NUMBER_OF_BLOCKS_FOR_TX_FINALIZATION) {
            return false;
        }
        return true;
    }

    private async _newestBlockNumber(): Promise<number> {
        const provider = this.signer.provider;
        if (provider === undefined) {
            throw("Signer is not connected to any provider");
        }
        return provider.getBlockNumber();
    }
}
