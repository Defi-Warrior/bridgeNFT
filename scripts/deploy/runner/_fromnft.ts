import { Signer } from "ethers";

import { FromNFT } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { getSigner, Role } from "../../utils/get-signer";
import { storeTokenInFromData } from "../../utils/data/store-deployed-token";
import { deploy as deployFromNFT } from "../function/_fromnft";

const network: Network = Network.LOCALHOST_8545;

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const fromToken: FromNFT = await deployFromNFT(deployer);
    
    // Store
    storeTokenInFromData(network, await fromToken.name(), fromToken.address);

    // Log address
    console.log("Deployed FromNFT contract's address:");
    console.log(fromToken.address);
})();
