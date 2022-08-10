import { Signer } from "ethers";

import { StaticBurningRevocableFromBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { storeStaticFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployFromNftFromBridge } from "../function/_fromnft-frombridge";

const network: NetworkInfo = NETWORK.LOCALHOST_8545;
const fromTokenAddr: string = "";

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, network);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, network)).getAddress();

    const fromNftFromBridge: StaticBurningRevocableFromBridge =
        await deployFromNftFromBridge(deployer, validatorAddr, fromTokenAddr);
    
    // Store.
    storeStaticFromBridge(network, fromTokenAddr, fromNftFromBridge.address, true);

    // Log address.
    console.log("Deployed FromNFT's StaticFromBridge contract's address:");
    console.log(fromNftFromBridge.address);
})();
