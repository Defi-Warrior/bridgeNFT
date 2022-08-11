import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DefiWarriorToBridge, DefiWarriorToBridge__factory } from "../../../typechain-types";

import DeployConfig from "../../types/config/deploy-config";

export async function deploy(
    deployer: Signer,
    toTokenAddr: string,
    validatorAddr: string,
    denierAddr: string,
    deployConfig: DeployConfig,
    nftManagerAddr: string
): Promise<DefiWarriorToBridge> {

    const defiWarriorToBridgeFactory: DefiWarriorToBridge__factory = await ethers.getContractFactory("DefiWarriorToBridge", deployer);
    
    const defiWarriorToBridge: DefiWarriorToBridge = await defiWarriorToBridgeFactory.deploy(
        toTokenAddr,
        validatorAddr,
        deployConfig.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED,
        denierAddr,
        deployConfig.GLOBAL_WAITING_DURATION_TO_ACQUIRE_BY_CLAIM,
        deployConfig.MINIMUM_ESCROW,
        nftManagerAddr);

    await defiWarriorToBridge.deployed();

    return defiWarriorToBridge;
}
