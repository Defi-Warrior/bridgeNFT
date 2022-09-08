import { resolve } from 'path';
// Libraries
import { BigNumber, BytesLike, Signer, utils } from "ethers";
import { ethers } from "hardhat";
import sodium from "libsodium-wrappers";

// Typechain
import { TypedEventFilter, TypedListener } from "../typechain-types/common";
import { IERC721, IClaimToBridge, IFromBridge } from "../typechain-types";
import { CommitEvent } from "../typechain-types/contracts/from/interfaces/IFromBridge";
import { ClaimEvent } from "../typechain-types/contracts/to/interfaces/IClaimToBridge";


// Project's modules
import DenierConfig from "./types/config/denier-config";
import { BridgeRequest, BridgeRequestId } from "./types/dto/bridge-request";
import { OwnerSignature } from "./utils/crypto/owner-signature";
import { ValidatorSignature } from "./utils/crypto/validator-signature";
import { getAddress, getSigner, Role } from "./utils/get-signer";
import { getNetworkInfo } from "../env/network";
import { NetworkInfo } from "./types/dto/network-info";

export class Denier {
    public readonly address: string;
    private _config: DenierConfig;

    // private _commitKey: Uint8Array;

    private constructor(config: DenierConfig) {
        this.address = getAddress(Role.DENIER);
        this._config = config;
        // this._commitKey = sodium.crypto_auth_keygen();
    }

    public static async instantiate(config: DenierConfig): Promise<Denier> {
        await sodium.ready;
        return new Denier(config);
    }

    private static _getSigner(chainId: number): Signer {
        return getSigner(Role.DENIER, getNetworkInfo(chainId));
    }

    /* ********************************************************************************************** */

    public async bindListenerToClaimEvent(
        toOwnerSigner: Signer,
        toBridgeAddr: string,
        requestNonce: BigNumber,
    ): Promise<{ commitment: string, requestTimestamp: BigNumber }> {
        const toBridge: IClaimToBridge = await ethers.getContractAt("IClaimToBridge", toBridgeAddr, toOwnerSigner);

        const filter: TypedEventFilter<ClaimEvent> = toBridge.filters.Claim(
            null, null, null, null, null);

        return new Promise((resolve, reject) => {
            const listener: TypedListener<ClaimEvent> = async (
                fromChainId, fromToken,
                fromBridge, commitment,
                claimTimestamp, event
            ) => {
                resolve({ commitment: commitment, requestTimestamp: claimTimestamp });
            };

            toBridge.once(filter, listener);
        });
    }

    public async isCommitTxFinalizedInFromBridge(requestId: BridgeRequestId, commitment: string): Promise<boolean> {
        const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", requestId.context.fromBridgeAddr);

        const filter: TypedEventFilter<CommitEvent> = fromBridge.filters.Commit(
            null, null, null, null,
            null, null, null, commitment, null);

        if (fromBridge.provider == undefined) {
            throw("Signer is not connected to any provider");
        }
        const newestBlock: number = await fromBridge.provider.getBlockNumber();
        const events: CommitEvent[] = await fromBridge.queryFilter(filter, newestBlock - 20, newestBlock);

        if (events.length == 0) {
            throw("Commit transaction for this request does not exist or has not yet been mined")
        }
        const event: CommitEvent = events[events.length - 1];

        if (newestBlock < event.blockNumber + this._config.NUMBER_OF_BLOCK_CONFIRMATIONS) {
            console.log(`Mined block: ${event.blockNumber} - Newest block: ${newestBlock}`);
            return false;
        }
        return true;
    }
}
