import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DynamicHoldingRevocableFromBridge, DynamicHoldingRevocableFromBridge__factory } from "../../../typechain-types";

export async function deploy(deployer: Signer, validatorAddr: string):
        Promise<DynamicHoldingRevocableFromBridge> {

    const dynamicHoldingRevocableFromBridgeFactory: DynamicHoldingRevocableFromBridge__factory =
        await ethers.getContractFactory("DynamicHoldingRevocableFromBridge", deployer);

    const dynamicHoldingRevocableFromBridge: DynamicHoldingRevocableFromBridge =
        await dynamicHoldingRevocableFromBridgeFactory.deploy(validatorAddr);

    await dynamicHoldingRevocableFromBridge.deployed();

    return dynamicHoldingRevocableFromBridge;
}
