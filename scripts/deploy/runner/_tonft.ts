import { Signer } from "ethers";

import { ToNFT } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { getSigner, Role } from "../../utils/get-signer";
import { storeTokenInToData } from "../../utils/data/store-deployed-token";
import { deploy as deployToNFT } from "../function/_tonft";

const network: Network = Network.LOCALHOST_8546;

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const toToken: ToNFT = await deployToNFT(deployer);
    
    // Store
    storeTokenInToData(network, await toToken.name(), toToken.address);

    // Log address
    console.log("Deployed ToNFT contract's address:");
    console.log(toToken.address);
})();
