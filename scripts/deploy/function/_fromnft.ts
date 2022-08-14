import { Signer } from "ethers";
import { ethers } from "hardhat";

import { FromNFT, FromNFT__factory } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(deployer: Signer, fromNetwork: NetworkInfo):
        Promise<FromNFT> {

    const fromNFTFactory: FromNFT__factory = await ethers.getContractFactory("FromNFT", deployer);
    const fromToken: FromNFT = await fromNFTFactory.deploy({ gasPrice: fromNetwork.GAS_PRICE });
    await fromToken.deployed();

    return fromToken;
}
