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

const fromNetwork:      NetworkInfo = NETWORK.LOCALHOST_8545;
const toNetwork:        NetworkInfo = NETWORK.LOCALHOST_8546;
const fromTokenAddr:    string = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const toTokenAddr:      string = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

async function main() {
    const fromBridgeAddr:   string = retrieveFromBridgeAddress(fromNetwork, fromTokenAddr);
    const toBridgeAddr:     string = retrieveToBridgeAddress(toNetwork, toTokenAddr);

    const validator: Validator = await Validator.instantiate(validatorConfig);

    const fromOwnerSigner: Signer = await getTokenOwnerSigner(fromNetwork);
    const toOwnerSigner:   Signer = await getTokenOwnerSigner(toNetwork);
    const tokenOwner: TokenOwner = new TokenOwner(await fromOwnerSigner.getAddress(), ownerConfig);

    // Mint token on FromNFT for test
    const tokenId: BigNumber = BigNumber.from(1);
    const tokenUri: string = "Du ne";
    const contractOwner: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const fromToken: FromNFT = await ethers.getContractAt("FromNFT", fromTokenAddr, contractOwner);
    await fromToken.mint(tokenOwner.address, tokenId, tokenUri);

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
    await tokenOwner.approveForAll(fromOwnerSigner, fromTokenAddr, fromBridgeAddr);
    // Could alternatively approve for the requested token only by calling:
    // tokenOwner.approve(fromToken, fromBridge, tokenId);
        
    // Step 1b: Get request nonce from FromBridge.
    const requestNonce: BigNumber = await tokenOwner.getRequestNonce(fromOwnerSigner, fromBridgeAddr);
    
    // Step 1c: Get token URI through FromBridge.
    const tokenUri: BytesLike = await tokenOwner.getTokenUri(
        fromOwnerSigner,
        fromTokenAddr,
        fromBridgeAddr,
        tokenId
    );

    // Step 1d: Ask validator authentication challenge.


    // Step 2: Sign bridge request.
    const bridgeRequest: BridgeRequest = new BridgeRequest(
        new BridgeRequestId(bridgeContext, tokenOwner.address, requestNonce),
        tokenId
    );
    const ownerSignature: BytesLike = await tokenOwner.signRequest(
        fromOwnerSigner,
        bridgeRequest,
        "0x00");
    
    // Step 3a: Bind listener to commit event at FromBridge.
    tokenOwner.bindListenerToCommitEvent(
        fromOwnerSigner,
        fromBridgeAddr,
        requestNonce,
        toOwnerSigner,
        validator,
        tokenUri);
        
    // (Step 3b: Send request to validator).

    /// PHASE 2: PROCESS REQUEST (COMMIT)
    /// SIDE: VALIDATOR (BACKEND)
    
    // (Step 1: Receive request).

    // Step 2: Process request (including committing to FromBridge).
    await validator.processRequest(bridgeRequest, ownerSignature);

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
