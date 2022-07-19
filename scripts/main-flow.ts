import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumberish, BytesLike } from "ethers";

import {
    FromBridge,
    FromBridge__factory,
    FromNFT, FromNFT__factory,
    IFromBridge,
    IToBridge,
    ToBridge,
    ToBridge__factory,
    ToNFT, ToNFT__factory
} from "../typechain-types";

import Config from "./config.develop";
import { Validator } from "./validator";
import { TokenOwner } from "./token-owner";
import { BridgeRequest, buildBridgeRequest } from "./dto/bridge-request";

async function main() {
    const deployer = (await ethers.getSigners())[0];
    const { fromToken, fromBridge, toToken, toBridge } = await deploy(deployer);

    await initialize(deployer, fromToken, fromBridge, toToken, toBridge);

    const validator: Validator = await Validator.instantiate( (await ethers.getSigners())[1] );
    const tokenOwner: TokenOwner = new TokenOwner( (await ethers.getSigners())[2] );

    // Mint token on FromNFT for test
    const tokenId: BigNumberish = 1;
    const tokenUri: string = "abc";
    fromToken.connect(deployer);
    await fromToken.mint(tokenOwner.address(), tokenId, tokenUri);

    const newTokenId = await bridge(fromToken, fromBridge, toToken, toBridge, validator, tokenOwner, tokenId);

    // Test if bridge succeeded
    console.log(toToken.ownerOf(newTokenId) === tokenOwner.address());
}

async function deploy(deployer: SignerWithAddress):
        Promise<{   fromToken: FromNFT, fromBridge: FromBridge,
                    toToken: ToNFT, toBridge: ToBridge }> {

    const fromNFT_factory: FromNFT__factory = await ethers.getContractFactory("FromNFT", deployer);
    const fromToken: FromNFT = await fromNFT_factory.deploy();
    await fromToken.deployed();

    const fromBridge_factory: FromBridge__factory = await ethers.getContractFactory("FromBridge", deployer);
    const fromBridge: FromBridge = await fromBridge_factory.deploy();
    await fromBridge.deployed();

    const toNFT_factory: ToNFT__factory = await ethers.getContractFactory("ToNFT", deployer);
    const toToken: ToNFT = await toNFT_factory.deploy();
    await toToken.deployed();

    const toBridge_factory: ToBridge__factory = await ethers.getContractFactory("ToBridge", deployer);
    const toBridge: ToBridge = await toBridge_factory.deploy();
    await toBridge.deployed();

    return {
        fromToken: fromToken,
        fromBridge: fromBridge,
        toToken: toToken,
        toBridge: toBridge
    };
}

async function initialize(
    contractOwner: SignerWithAddress,
    fromToken: FromNFT, fromBridge: FromBridge,
    toToken: ToNFT, toBridge: ToBridge,
) {
    fromBridge.connect(contractOwner);
    fromBridge.initialize(
        fromToken.address,
        toToken.address,
        toBridge.address,
        Config.VALIDATOR_ADDRESS
    );

    toToken.connect(contractOwner);
    toToken.setToBridge(toBridge.address);

    toBridge.connect(contractOwner);
    toBridge.initialize(
        fromToken.address,
        fromBridge.address,
        toToken.address,
        Config.VALIDATOR_ADDRESS,
        Config.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED
    );
}

async function bridge(
    fromToken: FromNFT, fromBridge: IFromBridge,
    toToken: ToNFT, toBridge: IToBridge,
    validator: Validator,
    tokenOwner: TokenOwner,
    tokenId: BigNumberish
): Promise<BigNumberish> {
    /// PHASE 1: CREATE REQUEST
    /// SIDE: OWNER (FRONTEND)

    // Step 1a: Approve FromBridge for all tokens.
    tokenOwner.approveForAll(fromToken, fromBridge);
    // Could alternatively approve for the requested token only by calling:
    // tokenOwner.approve(fromToken, fromBridge, tokenId);
        
    // Step 1b: Get request nonce from FromBridge.
    const requestNonce: BigNumberish = await tokenOwner.getRequestNonce(fromBridge, tokenId);

    // Step 1c: Ask validator authentication challenge.


    // Step 2: Sign bridge request.
    const ownerSignature: BytesLike = await tokenOwner.signRequest(
        fromToken, fromBridge,
        toToken, toBridge,
        tokenId, requestNonce);
        
    // Step 3: Build request then send to validator.
    const request: BridgeRequest = buildBridgeRequest(
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

    /// PHASE 3: LISTEN TO COMMIT TRANSACTION
    /// SIDE: OWNER (FRONTEND)

    return 0;
}

main();
