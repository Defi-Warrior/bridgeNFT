import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

import { FromBridge, FromBridge__factory, FromNFT, FromNFT__factory, ToBridge, ToBridge__factory, ToNFT, ToNFT__factory } from "../typechain-types";
import DeployConfig from "./types/config/deploy-config";

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
) {
    fromBridge.connect(contractOwner);
    fromBridge.initialize(
        fromToken.address,
        toToken.address,
        toBridge.address,
        deployConfig.ADDRESS_VALIDATOR
    );

    toToken.connect(contractOwner);
    toToken.setToBridge(toBridge.address);

    toBridge.connect(contractOwner);
    toBridge.initialize(
        fromToken.address,
        fromBridge.address,
        toToken.address,
        deployConfig.ADDRESS_VALIDATOR,
        deployConfig.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED
    );
}
