import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DynamicHoldingRevocableFromBridge, DynamicHoldingRevocableFromBridge__factory } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(deployer: Signer, validatorAddr: string, fromNetwork: NetworkInfo):
        Promise<DynamicHoldingRevocableFromBridge> {

    const dynamicHoldingRevocableFromBridgeFactory: DynamicHoldingRevocableFromBridge__factory =
        await ethers.getContractFactory("DynamicHoldingRevocableFromBridge", deployer);

    const dynamicHoldingRevocableFromBridge: DynamicHoldingRevocableFromBridge =
        await dynamicHoldingRevocableFromBridgeFactory.deploy(validatorAddr, { gasPrice: fromNetwork.GAS_PRICE });

    await dynamicHoldingRevocableFromBridge.deployed();

    return dynamicHoldingRevocableFromBridge;
}
