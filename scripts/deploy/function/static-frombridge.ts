import { Signer } from "ethers";
import { ethers } from "hardhat";

import { FromBridge, FromBridge__factory } from "../../../typechain-types";

export async function deploy(deployer: Signer):
        Promise<FromBridge> {

    const staticFromBridgeFactory: FromBridge__factory = await ethers.getContractFactory("FromBridge", deployer);
    const staticFromBridge: FromBridge = await staticFromBridgeFactory.deploy();
    await staticFromBridge.deployed();

    return staticFromBridge;
}

export async function initialize(
    staticFromBridge: FromBridge,
    contractOwner: Signer,
    fromTokenAddr: string,
    toTokenAddr: string, toBridgeAddr: string,
    validatorAddr: string
) {
    await staticFromBridge.connect(contractOwner).initialize(
        fromTokenAddr,
        toTokenAddr,
        toBridgeAddr,
        validatorAddr
    );
}
