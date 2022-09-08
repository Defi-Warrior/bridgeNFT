import { BigNumber, BytesLike, Signer, utils } from "ethers";
import { ethers } from "hardhat";

import { FromNFT, IERC721, IFromBridge, IToBridge } from "../typechain-types";

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

// Warrior NFT
// const fromNetwork:      NetworkInfo = NETWORK.BSC_TEST;
// const fromNetwork:      NetworkInfo = NETWORK.POLYGON_TEST_MUMBAI;
// const fromNetwork:      NetworkInfo = NETWORK.POLYGON_MAIN;

// const toNetwork:        NetworkInfo = NETWORK.BSC_TEST;
// const toNetwork:        NetworkInfo = NETWORK.POLYGON_TEST_MUMBAI;
// const toNetwork:        NetworkInfo = NETWORK.POLYGON_MAIN;
// Warrior
// const fromTokenAddr:    string      = "0x2c1449643E7D0C478eFC47f84AcbBbbF03399a79";
// const fromTokenAddr:    string      = "0xfd4D9e1122792dFF031e94c4378FaC48322dbF3e";
// const fromTokenAddr:    string      = "0x3821fa78B5c8E13C414D4418a408f65DC2529f64";

// const toTokenAddr:      string      = "0x2c1449643E7D0C478eFC47f84AcbBbbF03399a79";
// const toTokenAddr:      string      = "0xfd4D9e1122792dFF031e94c4378FaC48322dbF3e";
// const toTokenAddr:      string      = "0x3821fa78B5c8E13C414D4418a408f65DC2529f64";

// const tokenId:          BigNumber   = BigNumber.from(0);

// Test NFT
const fromNetwork:      NetworkInfo = NETWORK.LOCALHOST_8545;
// const fromNetwork:      NetworkInfo = NETWORK.LOCALHOST_8546;

// const toNetwork:        NetworkInfo = NETWORK.LOCALHOST_8545;
const toNetwork:        NetworkInfo = NETWORK.LOCALHOST_8546;

const fromTokenAddr:    string      = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const toTokenAddr:      string      = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

async function main() {
    const fromBridgeAddr:   string = retrieveFromBridgeAddress(fromNetwork, fromTokenAddr);
    const toBridgeAddr:     string = retrieveToBridgeAddress(toNetwork, toTokenAddr);

    const validator: Validator = await Validator.instantiate(validatorConfig);

    const fromOwnerSigner: Signer = await getTokenOwnerSigner(fromNetwork);
    const toOwnerSigner:   Signer = await getTokenOwnerSigner(toNetwork);
    const tokenOwner: TokenOwner = new TokenOwner(await fromOwnerSigner.getAddress(), ownerConfig);

    // Mint token on FromNFT for test
    console.log("0 Mint");
    const tokenId: BigNumber = BigNumber.from(1);
    const tokenUri: string = "Du ne";
    const contractOwner: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const fromToken: FromNFT = await ethers.getContractAt("FromNFT", fromTokenAddr, contractOwner);
    const mintTx = await fromToken.mint(tokenOwner.address, tokenId, tokenUri);
    await mintTx.wait();
    console.log("0 Done");

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
    const { fromChainId, fromTokenAddr, fromBridgeAddr } = bridgeContext;
    /// PHASE 1: CREATE REQUEST
    /// SIDE: OWNER (FRONTEND)

    // Step 1a: Approve FromBridge for all tokens.
    console.log("1 Approve FromBridge");
    await tokenOwner.approveForAll(fromOwnerSigner, fromTokenAddr, fromBridgeAddr, fromNetwork);
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
    const challenge: string = "0x00";

    // Step 2: Sign bridge request.
    const bridgeRequest: BridgeRequest = new BridgeRequest(
        new BridgeRequestId(bridgeContext, tokenOwner.address, requestNonce),
        tokenId
    );
    console.log("4 Owner signRequest");
    const ownerSignature: BytesLike = await tokenOwner.signRequest(
        fromOwnerSigner,
        bridgeRequest,
        challenge);
    console.log("4 Done");

    // Step 3a: Bind listener to commit event at FromBridge.
    console.log("5 bindListenerToCommitEvent");
    const commitPromise = tokenOwner.bindListenerToCommitEvent(
        fromOwnerSigner,
        fromBridgeAddr,
        requestNonce);
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
    // Step 1: Listen to commit transaction.
    const { commitment, requestTimestamp } = await commitPromise;
    console.log("7 Listen to commit success");

    // Step 2: Ask validator for secret.
    const requestId: BridgeRequestId = new BridgeRequestId(
        bridgeContext,
        tokenOwner.address,
        requestNonce
    );

    console.log("8 Wait commit tx finalization");
    while (! await tokenOwner.isCommitTxFinalized(fromOwnerSigner, requestId));
    console.log("8 Done");
    console.log("9 Validator revealSecret");
    const secret: BytesLike = await validator.revealSecret(requestId);
    console.log("9 Done");

    // Step 3: Retrieve validator signature.
    console.log("10 Owner getValidatorSignature");
    const fromBridge: IFromBridge = await ethers.getContractAt("IFromBridge", fromBridgeAddr, fromOwnerSigner);
    const validatorSignature: BytesLike =
        await fromBridge["getValidatorSignature(uint256)"](requestNonce);
    console.log("10 Done");

    // Step 4: Acquire new token.
    const origin: IToBridge.OriginStruct = {
        fromChainId: fromChainId,
        fromToken: fromTokenAddr,
        fromBridge: fromBridgeAddr
    };

    const oldTokenInfo: IToBridge.TokenInfoStruct = {
        tokenId: tokenId,
        tokenUri: tokenUri
    }

    const { toBridgeAddr } = bridgeContext;
    const toBridge: IToBridge = await ethers.getContractAt("IToBridge", toBridgeAddr, toOwnerSigner);
    console.log("11 Owner acquire");
    const acquireTx = await toBridge.acquire(
        origin,
        tokenOwner.address,
        oldTokenInfo,
        commitment, secret,
        requestTimestamp,
        validatorSignature,
        {
            gasLimit: 2000000,
            gasPrice: toNetwork.GAS_PRICE
        }
    );
    const acquireTxReceipt = await acquireTx.wait();
    console.log("11 Done");

    // Test if bridge succeeded.
    const logs = acquireTxReceipt.events;
    if (logs == undefined) {
        throw("No event emitted");
    }

    // Search for Acquire event.
    let logIndex: number = 0;
    for (let i in logs) {
        if (logs[i].address == toBridgeAddr &&
            logs[i].topics[0] == utils.id("Acquire(uint256,address,address,address,uint256,bytes32,uint256)")) {
            logIndex = parseInt(i);
            break;
        }
    }

    const eventArgs: any = logs[logIndex].args;
    const newTokenId: BigNumber = eventArgs["newTokenId"];
    console.log("New token ID:");
    console.log(newTokenId);

    const toToken: IERC721 = await ethers.getContractAt("IERC721", toTokenAddr, toOwnerSigner);
    console.log("Bridge success:");
    console.log(await toToken.ownerOf(newTokenId) === tokenOwner.address);
}

main();
