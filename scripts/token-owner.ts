import { BigNumberish, BytesLike, EventFilter, Signer, utils } from "ethers";
import { FromNFT, IFromBridge, IToBridge, ToNFT } from "../typechain-types";

import OwnerConfig from "./types/config/owner-config";
import { OwnerSignature } from "./utils/owner-signature";

export class TokenOwner {
    private signer: Signer;

    constructor(signer: Signer) {
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

    public async bindListenerToCommitEvent(
        fromBridge: IFromBridge,
        tokenId: BigNumberish, requestNonce: BigNumberish
    ) {
        // const filter: EventFilter = {
        //     address: fromBridge.address,
        //     topics: [
        //         utils.id("Commit(address,uint256,uint256,bytes32,uint256,bytes)"),
        //         await this.address(),
        //         tokenId, requestNonce
        //     ]
        // };
    }
}
