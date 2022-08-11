import { Signer } from "ethers";

import { DynamicBurningRevocableFromBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { storeDynamicBurningFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDynamicBurningRevocableFromBridge } from "../function/dynamic-burning-revocable-frombridge";

const network: NetworkInfo = NETWORK.LOCALHOST_8545;

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, network);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, network)).getAddress();
    
    const dynamicBurningRevocableFromBridge: DynamicBurningRevocableFromBridge =
        await deployDynamicBurningRevocableFromBridge(deployer, validatorAddr);

    // Store.
    storeDynamicBurningFromBridge(network, dynamicBurningRevocableFromBridge.address, true);

    // Log address.
    console.log("Deployed DynamicBurningRevocableFromBridge contract's address:");
    console.log(dynamicBurningRevocableFromBridge.address);
})();
