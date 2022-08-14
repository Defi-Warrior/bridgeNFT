import { Signer } from "ethers";
import { ethers } from "hardhat";

import { ToNftToBridge, ToNftToBridge__factory } from "../../../typechain-types";

import DeployConfig from "../../types/config/deploy-config";
import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(
    deployer: Signer,
    toTokenAddr: string,
    validatorAddr: string,
    denierAddr: string,
    deployConfig: DeployConfig,
    toNetwork: NetworkInfo
): Promise<ToNftToBridge> {

    const toNftToBridgeFactory: ToNftToBridge__factory = await ethers.getContractFactory("ToNftToBridge", deployer);
    
    const toNftToBridge: ToNftToBridge = await toNftToBridgeFactory.deploy(
        toTokenAddr,
        validatorAddr,
        deployConfig.GLOBAL_WAITING_DURATION_FOR_OLD_TOKEN_TO_BE_PROCESSED,
        denierAddr,
        deployConfig.GLOBAL_WAITING_DURATION_TO_ACQUIRE_BY_CLAIM,
        deployConfig.MINIMUM_ESCROW,
        { gasPrice: toNetwork.GAS_PRICE });

    await toNftToBridge.deployed();

    return toNftToBridge;
}
