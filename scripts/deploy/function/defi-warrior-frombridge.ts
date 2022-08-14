import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DefiWarriorFromBridge, DefiWarriorFromBridge__factory } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(
    deployer: Signer,
    validatorAddr: string,
    fromTokenAddr: string,
    fromBodyPartAddr: string,
    fromNetwork: NetworkInfo
): Promise<DefiWarriorFromBridge> {
    
    const defiWarriorFromBridgeFactory: DefiWarriorFromBridge__factory =
        await ethers.getContractFactory("DefiWarriorFromBridge", deployer);

    const defiWarriorFromBridge: DefiWarriorFromBridge =
        await defiWarriorFromBridgeFactory.deploy(validatorAddr, fromTokenAddr, fromBodyPartAddr, { gasPrice: fromNetwork.GAS_PRICE });
        
    await defiWarriorFromBridge.deployed();

    return defiWarriorFromBridge;
}
