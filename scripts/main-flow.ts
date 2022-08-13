import { BigNumber, BytesLike, Signer } from "ethers";
import { ethers } from "hardhat";

import { FromNFT } from "../typechain-types";

import { NETWORK }
    from "../env/network";
import { BridgeContext, BridgeRequest, BridgeRequestId }
    from "./types/dto/bridge-request";
import { NetworkInfo } from "./types/dto/network-info";
import { retrieveFromBridgeAddress, retrieveToBridgeAddress }
    from "./utils/data/retrieve-bridge-address";
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

const fromNetwork:      NetworkInfo = NETWORK.BSC_TEST;
const toNetwork:        NetworkInfo = NETWORK.POLYGON_MAIN;
// Warrior
const fromTokenAddr:    string      = "0x2c1449643E7D0C478eFC47f84AcbBbbF03399a79";
const toTokenAddr:      string      = "0x3821fa78B5c8E13C414D4418a408f65DC2529f64";
const tokenId:          BigNumber   = BigNumber.from(328);
// Test NFT
// const fromTokenAddr:    string      = "0xCF74aDC2c44aCE9b98C435Cc16d98fEb96bea268";
// const toTokenAddr:      string      = "0x93bf0F1Ede716CC2f72A8c7aEb830F7839f20029";

async function main() {
    const fromBridgeAddr:   string = retrieveFromBridgeAddress(fromNetwork, fromTokenAddr);
    const toBridgeAddr:     string = retrieveToBridgeAddress(toNetwork, toTokenAddr);

    const validator: Validator = await Validator.instantiate(validatorConfig);

    const fromOwnerSigner: Signer = await getTokenOwnerSigner(fromNetwork);
    // console.log(await fromOwnerSigner.getBalance());
    const toOwnerSigner:   Signer = await getTokenOwnerSigner(toNetwork);
    // console.log(await toOwnerSigner.getBalance());
    const tokenOwner: TokenOwner = new TokenOwner(await fromOwnerSigner.getAddress(), ownerConfig);

    // Mint token on FromNFT for test
    // console.log("0 Mint");
    // const tokenId: BigNumber = BigNumber.from(0);
    // const tokenUri: string = "Du ne";
    // const contractOwner: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    // const fromToken: FromNFT = await ethers.getContractAt("FromNFT", fromTokenAddr, contractOwner);
    // const mintTx = await fromToken.mint(tokenOwner.address, tokenId, tokenUri);
    // await mintTx.wait();
    // console.log("0 Done");

    const bridgeContext: BridgeContext = new BridgeContext(
        fromNetwork.CHAIN_ID, fromTokenAddr, fromBridgeAddr,
        toNetwork.CHAIN_ID, toTokenAddr, toBridgeAddr
    );

    await bridge(bridgeContext, validator, tokenOwner, fromOwnerSigner, toOwnerSigner, tokenId);
}

async function bridge(
    bridgeContext: BridgeContext,
    validator: Validator,
    tokenOwner: TokenOwner,
    fromOwnerSigner: Signer,
    toOwnerSigner: Signer,
    tokenId: BigNumber
) {
    const { fromTokenAddr, fromBridgeAddr } = bridgeContext;
    /// PHASE 1: CREATE REQUEST
    /// SIDE: OWNER (FRONTEND)

    // Step 1a: Approve FromBridge for all tokens.
    console.log("1 Approve FromBridge");
    await tokenOwner.approveForAll(fromOwnerSigner, fromTokenAddr, fromBridgeAddr);
    console.log("1 Done");
    // Could alternatively approve for the requested token only by calling:
    // tokenOwner.approve(fromToken, fromBridge, tokenId);
        
    // Step 1b: Get request nonce from FromBridge.
    console.log("2 Owner getRequestNonce");
    const requestNonce: BigNumber = await tokenOwner.getRequestNonce(fromOwnerSigner, fromBridgeAddr);
    console.log("2 Done");
    
    // Step 1c: Get token URI through FromBridge.
    console.log("3 Owner getTokenUri");
    const tokenUri: BytesLike = await tokenOwner.getTokenUri(
        fromOwnerSigner,
        fromTokenAddr,
        fromBridgeAddr,
        tokenId
    );
    console.log("3 Done");

    // Step 1d: Ask validator authentication challenge.


    // Step 2: Sign bridge request.
    const bridgeRequest: BridgeRequest = new BridgeRequest(
        new BridgeRequestId(bridgeContext, tokenOwner.address, requestNonce),
        tokenId
    );
    console.log("4 Owner signRequest");
    const ownerSignature: BytesLike = await tokenOwner.signRequest(
        fromOwnerSigner,
        bridgeRequest,
        "0x00");
    console.log("4 Done");
    
    // Step 3a: Bind listener to commit event at FromBridge.
    console.log("5 bindListenerToCommitEvent");
    tokenOwner.bindListenerToCommitEvent(
        fromOwnerSigner,
        fromBridgeAddr,
        requestNonce,
        toOwnerSigner,
        validator,
        tokenUri);
    console.log("5 Done");
        
    // (Step 3b: Send request to validator).

    /// PHASE 2: PROCESS REQUEST (COMMIT)
    /// SIDE: VALIDATOR (BACKEND)
    
    // (Step 1: Receive request).

    // Step 2: Process request (including committing to FromBridge).
    console.log("6 Validator processRequest");
    await validator.processRequest(bridgeRequest, ownerSignature);
    console.log("6 Done");

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
