import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { FromBridge, FromBridge__factory, FromNFT, FromNFT__factory, ToBridge, ToBridge__factory, ToNFT, ToNFT__factory } from "../typechain-types";

import ENV from "../env";
import DeployConfig from "./types/config/deploy-config";
import getDeployerSigner from "./utils/get-deployer-signer";
import getValidatorSigner from "./utils/get-validator-signer";
import BridgeContext from "./types/dto/bridge-context";

(async () => {
    // Deploy
    const deployer: SignerWithAddress = await getDeployerSigner();
    const { fromToken, fromBridge, toToken, toBridge } = await deploy(deployer);
    
    // Initialize
    const { deployConfig } = require("./config." + ENV + ".ts");
    const validatorAddr: string = (await getValidatorSigner()).address;
    await initialize(deployConfig, deployer, fromToken, fromBridge, toToken, toBridge, validatorAddr); 
    
    // Write deployed contracts' addresses to file
    const bridgeContext: BridgeContext = new BridgeContext(
        fromToken.address, fromBridge.address,
        toToken.address, toBridge.address,
        validatorAddr);
    
    bridgeContext.writeToJson(__dirname + "/../deployed/" + ENV + "/bridge-context.json");
})();

export async function deploy(deployer: SignerWithAddress):
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

export async function initialize(
    deployConfig: DeployConfig,
    contractOwner: SignerWithAddress,
    fromToken: FromNFT, fromBridge: FromBridge,
    toToken: ToNFT, toBridge: ToBridge,
    validatorAddr: string
) {
    await fromBridge.connect(contractOwner).initialize(
        fromToken.address,
        toToken.address,
        toBridge.address,
        validatorAddr
    );

    await toToken.connect(contractOwner).setToBridge(toBridge.address);

    await toBridge.connect(contractOwner).initialize(
        fromToken.address,
        fromBridge.address,
        toToken.address,
        validatorAddr,
        deployConfig.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED
    );
}
