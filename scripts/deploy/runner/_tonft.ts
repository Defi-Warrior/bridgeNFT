import { Signer } from "ethers";

import { ToNFT } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { getSigner, Role } from "../../utils/get-signer";
import { storeTokenInToData } from "../../utils/data/store-deployed-token";
import { deploy as deployToNFT } from "../function/_tonft";

const network: NetworkInfo = NETWORK.LOCALHOST_8546;

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, network);
    const toToken: ToNFT = await deployToNFT(deployer);
    
    // Store.
    storeTokenInToData(network, toToken.address, {
        NAME: await toToken.name()
    });

    // Log address.
    console.log("Deployed ToNFT contract's address:");
    console.log(toToken.address);
})();
