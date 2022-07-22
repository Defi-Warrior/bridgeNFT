import { BigNumber, BytesLike, Signer } from "ethers";
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
        const fromToken_: FromNFT = fromToken.connect(this.signer);
        if (! await fromToken_.isApprovedForAll(await this.address(), fromBridge.address)) {
            fromToken_.setApprovalForAll(fromBridge.address, true);
        }
    }

    public async approve(fromToken: FromNFT, fromBridge: IFromBridge, tokenId: BigNumber) {
        const fromToken_: FromNFT = fromToken.connect(this.signer);
        if (!  (await fromToken_.isApprovedForAll(await this.address(), fromBridge.address) ||
                await fromToken_.getApproved(tokenId) === fromBridge.address) ) {
            fromToken_.approve(fromBridge.address, tokenId);
        }
    }

    public async getRequestNonce(fromBridge: IFromBridge, tokenId: BigNumber): Promise<BigNumber> {
        return fromBridge.connect(this.signer).getRequestNonce(tokenId);
    }
    
    public async signRequest(
        fromToken: FromNFT, fromBridge: IFromBridge,
        toToken: ToNFT, toBridge: IToBridge,
        tokenId: BigNumber, requestNonce: BigNumber
    ): Promise<BytesLike> {
        return OwnerSignature.sign(
            this.signer,
            fromToken.address, fromBridge.address,
            toToken.address, toBridge.address,
            tokenId, requestNonce
        );
    }

    public async bindListenerToCommitEvent(
        fromToken: FromNFT, fromBridge: IFromBridge,
        toBridge: IToBridge,
        tokenId: BigNumber, requestNonce: BigNumber,
        validator: Validator
    ) {
        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            await this.address(),
            tokenId,
            requestNonce);
        
        const listener: TypedListener<CommitEvent> = async (
            tokenOwner,
            tokenId, requestNonce,
            tokenUri,
            commitment, requestTimestamp,
            validatorSignature,
            event
        ) => {
            // Ask validator for secret.
            const requestid: BridgeRequestId = {
                tokenOwner: tokenOwner,
                tokenId: tokenId,
                requestNonce: requestNonce
            }
            while (! await this._isCommitTxFinalized(fromBridge, requestid));
            const secret: BytesLike = await validator.revealSecret(fromBridge, requestid);

            // Acquire new token.
            await toBridge.connect(this.signer).acquire(
                await this.address(),
                tokenId, tokenUri,
                commitment, secret,
                requestTimestamp,
                validatorSignature
            );
        };
        
        fromBridge.connect(this.signer).once(filter, listener);
    }

    private async _isCommitTxFinalized(fromBridge: IFromBridge, requestId: BridgeRequestId): Promise<boolean> {
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
