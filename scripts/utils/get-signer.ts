import { BytesLike, Signer, Wallet } from "ethers";
import { ethers } from "hardhat";

import { NetworkInfo } from "../types/dto/network-info";

export enum Role {
    DEPLOYER = "DEPLOYER",
    VALIDATOR = "VALIDATOR",
    DENIER = "DENIER"
}

export function getSigner(role: Role, network: NetworkInfo): Signer {
    const privateKey: BytesLike | undefined = process.env[role + "_PRIVATE_KEY"];
    if (privateKey == undefined) {
        throw(role + "'s private key is not provided");
    }

    const provider = ethers.getDefaultProvider(network.RPC_URL);

    return new Wallet(privateKey, provider);
}

export function getAddress(role: Role): string {
    const privateKey: BytesLike | undefined = process.env[role + "_PRIVATE_KEY"];
    if (privateKey == undefined) {
        throw(role + "'s private key is not provided");
    }

    return new Wallet(privateKey).address;
}
