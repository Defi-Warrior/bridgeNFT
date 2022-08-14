import { Signer } from "ethers";

import { StaticBurningRevocableFromBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { storeStaticFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployFromNftFromBridge } from "../function/_fromnft-frombridge";

const fromNetwork: NetworkInfo = NETWORK.LOCALHOST_8545;
const fromTokenAddr: string = "";

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, fromNetwork)).getAddress();

    const fromNftFromBridge: StaticBurningRevocableFromBridge =
        await deployFromNftFromBridge(deployer, validatorAddr, fromTokenAddr, fromNetwork);
    
    // Store.
    storeStaticFromBridge(fromNetwork, fromTokenAddr, fromNftFromBridge.address, true);

    // Log address.
    console.log("Deployed FromNFT's StaticFromBridge contract's address:");
    console.log(fromNftFromBridge.address);
})();
