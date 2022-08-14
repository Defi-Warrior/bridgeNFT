import { Signer } from "ethers";
import { ethers } from "hardhat";

import { StaticBurningRevocableFromBridge, StaticBurningRevocableFromBridge__factory } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(
    deployer: Signer,
    validatorAddr: string,
    fromTokenAddr: string,
    fromNetwork: NetworkInfo
): Promise<StaticBurningRevocableFromBridge> {
    
    const fromNftFromBridgeFactory: StaticBurningRevocableFromBridge__factory =
        await ethers.getContractFactory("StaticBurningRevocableFromBridge", deployer);

    const fromNftFromBridge: StaticBurningRevocableFromBridge =
        await fromNftFromBridgeFactory.deploy(validatorAddr, fromTokenAddr, { gasPrice: fromNetwork.GAS_PRICE });
        
    await fromNftFromBridge.deployed();

    return fromNftFromBridge;
}
