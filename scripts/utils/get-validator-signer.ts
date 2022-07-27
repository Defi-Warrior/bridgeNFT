import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export default async function getValidatorSigner(): Promise<SignerWithAddress> {
    const signers: SignerWithAddress[] = await ethers.getSigners();
    if (signers.length == 0) {
        throw("No account provided");
    }
    if (signers.length == 1) {
        // When one address is used for both deployer and validator.
        return signers[0];
    }
    return signers[1];
}
