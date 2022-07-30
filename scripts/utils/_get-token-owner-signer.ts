import { BytesLike, Signer, Wallet } from "ethers";
import { ethers } from "hardhat";

import Network from "../types/network-enum";
import { retrieveNetworkInfo } from "./data/env-io";

export async function getTokenOwnerSigner(networkName: Network): Promise<Signer> {
    const privateKey: BytesLike | undefined = process.env["TOKEN_OWNER_PRIVATE_KEY"];
    if (privateKey == undefined) {
        throw("TOKEN_OWNER's private key is not provided");
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
