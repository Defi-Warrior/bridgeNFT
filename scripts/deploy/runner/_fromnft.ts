import { Signer } from "ethers";

import { FromNFT } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { getSigner, Role } from "../../utils/get-signer";
import { storeTokenInFromData } from "../../utils/data/store-deployed-token";
import { deploy as deployFromNFT } from "../function/_fromnft";

const fromNetwork: NetworkInfo = NETWORK.LOCALHOST_8545;

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const fromToken: FromNFT = await deployFromNFT(deployer, fromNetwork);
    
    // Store.
    storeTokenInFromData(fromNetwork, fromToken.address, {
        NAME: await fromToken.name(),
        DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY: true,
        DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY: true
    });

    // Log address.
    console.log("Deployed FromNFT contract's address:");
    console.log(fromToken.address);
})();
