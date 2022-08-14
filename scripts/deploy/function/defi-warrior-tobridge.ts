import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DefiWarriorToBridge, DefiWarriorToBridge__factory } from "../../../typechain-types";

import DeployConfig from "../../types/config/deploy-config";
import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(
    deployer: Signer,
    toTokenAddr: string,
    validatorAddr: string,
    denierAddr: string,
    deployConfig: DeployConfig,
    nftManagerAddr: string,
    toNetwork: NetworkInfo
): Promise<DefiWarriorToBridge> {

    const defiWarriorToBridgeFactory: DefiWarriorToBridge__factory = await ethers.getContractFactory("DefiWarriorToBridge", deployer);
    
    const defiWarriorToBridge: DefiWarriorToBridge = await defiWarriorToBridgeFactory.deploy(
        toTokenAddr,
        validatorAddr,
        deployConfig.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED,
        denierAddr,
        deployConfig.GLOBAL_WAITING_DURATION_TO_ACQUIRE_BY_CLAIM,
        deployConfig.MINIMUM_ESCROW,
        nftManagerAddr,
        { gasPrice: toNetwork.GAS_PRICE });

    await defiWarriorToBridge.deployed();

    return defiWarriorToBridge;
}
