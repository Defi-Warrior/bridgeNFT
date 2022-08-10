import { BytesLike, Signer, Wallet } from "ethers";
import { ethers } from "hardhat";

import Network from "../types/network-enum";
import { retrieveNetworkInfo } from "./data/env-io";

export enum Role {
    DEPLOYER = "DEPLOYER",
    VALIDATOR = "VALIDATOR",
    DENIER = "DENIER"
}

export async function getSigner(role: Role, networkName: Network): Promise<Signer> {
    const privateKey: BytesLike | undefined = process.env[role + "_PRIVATE_KEY"];
    if (privateKey == undefined) {
        throw(role + "'s private key is not provided");
    }

    const network: Record<string, any> = retrieveNetworkInfo()[networkName];
    if (network == undefined) {
        throw(networkName + " is not supported");
    }
    if (network["URL"] == undefined) {
        throw(networkName + "'s URL is not found");
    }
    const provider = ethers.getDefaultProvider(network["URL"]);

    return new Wallet(privateKey, provider);
}
