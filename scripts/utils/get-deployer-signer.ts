import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export default async function getDeployerSigner(): Promise<SignerWithAddress> {
    const signers: SignerWithAddress[] = await ethers.getSigners();
    if (signers.length == 0) {
        throw("No account provided");
    }
    return signers[0];
}
