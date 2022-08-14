import { Signer } from "ethers";
import { ethers } from "hardhat";

import { DynamicBurningRevocableFromBridge, DynamicBurningRevocableFromBridge__factory } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(deployer: Signer, validatorAddr: string, fromNetwork: NetworkInfo):
        Promise<DynamicBurningRevocableFromBridge> {

    const dynamicBurningRevocableFromBridgeFactory: DynamicBurningRevocableFromBridge__factory =
        await ethers.getContractFactory("DynamicBurningRevocableFromBridge", deployer);

    const dynamicBurningRevocableFromBridge: DynamicBurningRevocableFromBridge =
        await dynamicBurningRevocableFromBridgeFactory.deploy(validatorAddr, { gasPrice: fromNetwork.GAS_PRICE });

    await dynamicBurningRevocableFromBridge.deployed();

    return dynamicBurningRevocableFromBridge;
}
