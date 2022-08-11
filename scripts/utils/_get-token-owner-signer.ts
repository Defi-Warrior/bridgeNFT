import { BytesLike, Signer, Wallet } from "ethers";
import { ethers } from "hardhat";

import { NetworkInfo } from "../types/dto/network-info";

export async function getTokenOwnerSigner(network: NetworkInfo): Promise<Signer> {
    const privateKey: BytesLike | undefined = process.env["TOKEN_OWNER_PRIVATE_KEY"];
    if (privateKey == undefined) {
        throw("TOKEN_OWNER's private key is not provided");
    }

    const provider = ethers.getDefaultProvider(network.RPC_URL);
    
    return new Wallet(privateKey, provider);
}
