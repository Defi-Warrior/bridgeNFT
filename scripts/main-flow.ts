import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BytesLike } from "ethers";

import {
    FromNFT,
    ToNFT,
    IFromBridge,
    IToBridge
} from "../typechain-types";

import { deployConfig, ownerConfig, validatorConfig } from "./config.develop";
import { Validator } from "./validator";
import { TokenOwner } from "./token-owner";
import { BridgeRequest } from "./types/dto/bridge-request";
import { deploy, initialize } from "./deploy";
import { TypedEventFilter } from "../typechain-types/common";
import { AcquireEvent } from "../typechain-types/contracts/interfaces/IToBridge";

async function main() {
    const deployer: SignerWithAddress = (await ethers.getSigners())[0];
    const { fromToken, fromBridge, toToken, toBridge } = await deploy(deployer);

    await initialize(deployConfig, deployer, fromToken, fromBridge, toToken, toBridge);

    const validator: Validator = await Validator.instantiate( validatorConfig, (await ethers.getSigners())[1] );
    const tokenOwner: TokenOwner = new TokenOwner( ownerConfig, (await ethers.getSigners())[2] );

    // Mint token on FromNFT for test
    const tokenId: BigNumber = BigNumber.from(1);
    const tokenUri: string = "abc";
    fromToken.connect(deployer);
    await fromToken.mint(tokenOwner.address(), tokenId, tokenUri);

    await bridge(fromToken, fromBridge, toToken, toBridge, validator, tokenOwner, tokenId);
    
    // Test if bridge succeeded
    const filter: TypedEventFilter<AcquireEvent> = toBridge.filters.Acquire(await tokenOwner.address(), tokenId);
    toBridge.once(filter, async (
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
        console.log(await toToken.ownerOf(newTokenId) === await tokenOwner.address());
    });
}

async function bridge(
    fromToken: FromNFT, fromBridge: IFromBridge,
    toToken: ToNFT, toBridge: IToBridge,
    validator: Validator,
    tokenOwner: TokenOwner,
    tokenId: BigNumber
) {
    /// PHASE 1: CREATE REQUEST
    /// SIDE: OWNER (FRONTEND)

    // Step 1a: Approve FromBridge for all tokens.
    tokenOwner.approveForAll(fromToken, fromBridge);
    // Could alternatively approve for the requested token only by calling:
    // tokenOwner.approve(fromToken, fromBridge, tokenId);
        
    // Step 1b: Get request nonce from FromBridge.
    const requestNonce: BigNumber = await tokenOwner.getRequestNonce(fromBridge, tokenId);
    
    // Step 1c: Ask validator authentication challenge.


    // Step 2: Sign bridge request.
    const ownerSignature: BytesLike = await tokenOwner.signRequest(
        fromToken, fromBridge,
        toToken, toBridge,
        tokenId, requestNonce);
    
    // Step 3a: Bind listener to commit event at FromBridge.
    tokenOwner.bindListenerToCommitEvent(fromToken, fromBridge, toBridge, tokenId, requestNonce, validator);
        
    // Step 3b: Build request then send to validator.
    const request: BridgeRequest = new BridgeRequest(
        await tokenOwner.address(),
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
