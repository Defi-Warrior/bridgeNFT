import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DynamicBurningRevocableFromBridge, DynamicBurningRevocableFromBridge__factory } from "../../../typechain-types";

export async function deploy(deployer: Signer, validatorAddr: string):
        Promise<DynamicBurningRevocableFromBridge> {

    const dynamicBurningRevocableFromBridgeFactory: DynamicBurningRevocableFromBridge__factory =
        await ethers.getContractFactory("DynamicBurningRevocableFromBridge", deployer);

    const dynamicBurningRevocableFromBridge: DynamicBurningRevocableFromBridge =
        await dynamicBurningRevocableFromBridgeFactory.deploy(validatorAddr);

    await dynamicBurningRevocableFromBridge.deployed();

    return dynamicBurningRevocableFromBridge;
}
