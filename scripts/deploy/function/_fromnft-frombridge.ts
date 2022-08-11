import { Signer } from "ethers";
import { ethers } from "hardhat";

import { StaticBurningRevocableFromBridge, StaticBurningRevocableFromBridge__factory } from "../../../typechain-types";

export async function deploy(
    deployer: Signer,
    validatorAddr: string,
    fromTokenAddr: string
): Promise<StaticBurningRevocableFromBridge> {
    
    const fromNftFromBridgeFactory: StaticBurningRevocableFromBridge__factory =
        await ethers.getContractFactory("StaticBurningRevocableFromBridge", deployer);

    const fromNftFromBridge: StaticBurningRevocableFromBridge =
        await fromNftFromBridgeFactory.deploy(validatorAddr, fromTokenAddr);
        
    await fromNftFromBridge.deployed();

    return fromNftFromBridge;
}
