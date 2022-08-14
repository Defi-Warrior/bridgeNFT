import { Signer } from "ethers";
import { ethers } from "hardhat";

import { ToNFT, ToNFT__factory } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";

export async function deploy(deployer: Signer, toNetwork: NetworkInfo):
        Promise<ToNFT> {

    const toNFTFactory: ToNFT__factory = await ethers.getContractFactory("ToNFT", deployer);
    const toToken: ToNFT = await toNFTFactory.deploy({ gasPrice: toNetwork.GAS_PRICE });
    await toToken.deployed();

    return toToken;
}

export async function initialize(toToken: ToNFT, contractOwner: Signer, toBridgeAddr: string) {
    await toToken.connect(contractOwner).setToBridge(toBridgeAddr);
    await toToken.connect(contractOwner).setAllowMint(true);
}
