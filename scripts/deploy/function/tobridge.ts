import { Signer } from "ethers";
import { ethers } from "hardhat";

import { ToBridge, ToBridge__factory } from "../../../typechain-types";

import DeployConfig from "../../types/config/deploy-config";

export async function deploy(deployer: Signer):
        Promise<ToBridge> {

    const toBridgeFactory: ToBridge__factory = await ethers.getContractFactory("ToBridge", deployer);
    const toBridge: ToBridge = await toBridgeFactory.deploy();
    await toBridge.deployed();

    return toBridge;
}

export async function initialize(
    toBridge: ToBridge,
    contractOwner: Signer,
    fromTokenAddr: string,
    fromBridgeAddr: string,
    toTokenAddr: string,
    validatorAddr: string,
    deployConfig: DeployConfig
) {
    await toBridge.connect(contractOwner).initialize(
        fromTokenAddr,
        fromBridgeAddr,
        toTokenAddr,
        validatorAddr,
        deployConfig.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED
    );
}
