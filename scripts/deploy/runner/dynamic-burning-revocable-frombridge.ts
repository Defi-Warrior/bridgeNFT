import { Signer } from "ethers";

import { DynamicBurningRevocableFromBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { storeDynamicFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDynamicBurningRevocableFromBridge } from "../function/dynamic-burning-revocable-frombridge";

const network: Network = Network.LOCALHOST_8545;

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    
    const dynamicBurningRevocableFromBridge: DynamicBurningRevocableFromBridge =
        await deployDynamicBurningRevocableFromBridge(deployer, validatorAddr);

    // Store
    storeDynamicFromBridge(network, dynamicBurningRevocableFromBridge.address);

    // Log address
    console.log("Deployed DynamicBurningRevocableFromBridge contract's address:");
    console.log(dynamicBurningRevocableFromBridge.address);
})();
