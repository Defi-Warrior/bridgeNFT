import { Signer } from "ethers";
import { ethers } from "hardhat";

import { FromNFT, FromNFT__factory } from "../../../typechain-types";

export async function deploy(deployer: Signer):
        Promise<FromNFT> {

    const fromNFTFactory: FromNFT__factory = await ethers.getContractFactory("FromNFT", deployer);
    const fromToken: FromNFT = await fromNFTFactory.deploy();
    await fromToken.deployed();

    return fromToken;
}
