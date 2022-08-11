import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DefiWarriorFromBridge, DefiWarriorFromBridge__factory } from "../../../typechain-types";

export async function deploy(
    deployer: Signer,
    validatorAddr: string,
    fromTokenAddr: string,
    fromBodyPartAddr: string
): Promise<DefiWarriorFromBridge> {
    
    const defiWarriorFromBridgeFactory: DefiWarriorFromBridge__factory =
        await ethers.getContractFactory("DefiWarriorFromBridge", deployer);

    const defiWarriorFromBridge: DefiWarriorFromBridge =
        await defiWarriorFromBridgeFactory.deploy(validatorAddr, fromTokenAddr, fromBodyPartAddr);
        
    await defiWarriorFromBridge.deployed();

    return defiWarriorFromBridge;
}
