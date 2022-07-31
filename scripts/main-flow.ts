import { BigNumber, BytesLike, Signer } from "ethers";
import { ethers } from "hardhat";

import { FromNFT, ToNFT, IFromBridge, IToBridge, FromBridge, ToBridge } from "../typechain-types";
import { TypedEventFilter } from "../typechain-types/common";
import { AcquireEvent } from "../typechain-types/contracts/interfaces/IToBridge";

import { BridgeRequest }
    from "./types/dto/bridge-request";
import { FromTokenInfo, ToTokenInfo }
    from "./types/dto/token-info";
import Network
    from "./types/network-enum";
import { retrieveDynamicFromBridge }
    from "./utils/data/retrieve-dynamic-frombridge";
import { retrieveTokenInfoInFromData, retrieveTokenInfoInToData }
    from "./utils/data/retrieve-token-info";
import { ownerConfig, validatorConfig }
    from "./utils/config";
import { getSigner, Role }
    from "./utils/get-signer";
import { getTokenOwnerSigner }
    from "./utils/_get-token-owner-signer";
import { Validator }
    from "./validator";
import { TokenOwner }
    from "./token-owner";
import deployAll from "./deploy/function/_deploy-all";

const fromNetwork:  Network = Network.LOCALHOST_8545;
const toNetwork:    Network = Network.LOCALHOST_8546;

async function main() {
    await deployAll(fromNetwork, toNetwork);

    const fromTokenInfo: FromTokenInfo = retrieveTokenInfoInFromData(fromNetwork, "FromNFT");
    const fromToken: FromNFT = await ethers.getContractAt("FromNFT", fromTokenInfo.ADDRESS);
    const fromBridgeAddr: string =
        fromTokenInfo.DYNAMIC_FROMBRIDGE_COMPATIBILITY ? retrieveDynamicFromBridge(fromNetwork) : fromTokenInfo.STATIC_FROMBRIDGE;
    const fromBridge: FromBridge = await ethers.getContractAt("FromBridge", fromBridgeAddr);

    const toTokenInfo: ToTokenInfo = retrieveTokenInfoInToData(toNetwork, "ToNFT");
    const toToken: ToNFT = await ethers.getContractAt("ToNFT", toTokenInfo.ADDRESS);
    if (toTokenInfo.TOBRIDGE == undefined) {
        throw("ToBridge not available");
    }
    const toBridge: ToBridge = await ethers.getContractAt("ToBridge", toTokenInfo.TOBRIDGE);

    const validator: Validator = await Validator.instantiate(await getSigner(Role.VALIDATOR, fromNetwork), validatorConfig);

    const tokenOwnerFromSigner: Signer = await getTokenOwnerSigner(fromNetwork);
    const tokenOwnerToSigner: Signer = await getTokenOwnerSigner(toNetwork);
    const tokenOwner: TokenOwner = new TokenOwner(await tokenOwnerFromSigner.getAddress(), ownerConfig);

    // Mint token on FromNFT for test
    const tokenId: BigNumber = BigNumber.from(1);
    const tokenUri: string = "abc";
    const contractOwner: Signer = await getSigner(Role.DEPLOYER, fromNetwork);
    await fromToken.connect(contractOwner).mint(tokenOwner.address, tokenId, tokenUri);
    
    // Test if bridge succeeded
    const filter: TypedEventFilter<AcquireEvent> = toBridge.filters.Acquire(tokenOwner.address, tokenId);
    toBridge.connect(tokenOwnerToSigner).once(filter, async (
        acquirer,
        oldTokenId,
        newTokenId,
        tokenUri,
        commitment,
        requestTimestamp,
        waitingDurationForOldTokenToBeProcessed,
        acquirementTimestamp,
        event
    ) => {
        console.log("Bridge success:");
        console.log(await toToken.connect(tokenOwnerToSigner).ownerOf(newTokenId) === tokenOwner.address);
        console.log(newTokenId);
    });

    await bridge(fromToken, fromBridge, toToken, toBridge, validator, tokenOwner, tokenOwnerFromSigner, tokenOwnerToSigner, tokenId);
}

async function bridge(
    fromToken: FromNFT, fromBridge: IFromBridge,
    toToken: ToNFT, toBridge: IToBridge,
    validator: Validator,
    tokenOwner: TokenOwner,
    tokenOwnerFromSigner: Signer,
    tokenOwnerToSigner: Signer,
    tokenId: BigNumber
) {
    /// PHASE 1: CREATE REQUEST
    /// SIDE: OWNER (FRONTEND)

    // Step 1a: Approve FromBridge for all tokens.
    await tokenOwner.approveForAll(tokenOwnerFromSigner, fromToken, fromBridge);
    // Could alternatively approve for the requested token only by calling:
    // tokenOwner.approve(fromToken, fromBridge, tokenId);
        
    // Step 1b: Get request nonce from FromBridge.
    const requestNonce: BigNumber = await tokenOwner.getRequestNonce(tokenOwnerFromSigner, fromBridge, tokenId);
    
    // Step 1c: Ask validator authentication challenge.


    // Step 2: Sign bridge request.
    const ownerSignature: BytesLike = await tokenOwner.signRequest(
        tokenOwnerFromSigner,
        fromToken, fromBridge,
        toToken, toBridge,
        tokenId, requestNonce);
    
    // Step 3a: Bind listener to commit event at FromBridge.
    tokenOwner.bindListenerToCommitEvent(
        tokenOwnerFromSigner, tokenOwnerToSigner,
        fromToken, fromBridge,
        toBridge,
        tokenId, requestNonce,
        validator);
        
    // Step 3b: Build request then send to validator.
    const request: BridgeRequest = new BridgeRequest(
        tokenOwner.address,
        tokenId, requestNonce,
        ownerSignature
    );

    /// PHASE 2: PROCESS REQUEST (COMMIT)
    /// SIDE: VALIDATOR (BACKEND)
    
    // (Step 1: Receive request).

    // Step 2: Process request (including committing to FromBridge).
    await validator.processRequest(
        fromToken, fromBridge,
        toToken, toBridge,
        request
    );

    /// PHASE 3: LISTEN TO COMMIT TRANSACTION -> ASK FOR SECRET -> ACQUIRE NEW TOKEN
    /// SIDE: OWNER (FRONTEND)
    // // Step 1: Listen to commit transaction.
    // const tokenUri;
    // const commitment;
    // const requestTimestamp;
    // const validatorSignature;

    // // Step 2: Ask validator for secret.
    // const secret;

    // // Step 3: Acquire new token.
    // toBridge.acquire(
    //     await tokenOwner.address(),
    //     tokenId, tokenUri,
    //     commitment, secret,
    //     requestTimestamp,
    //     validatorSignature
    // )
}

main();
