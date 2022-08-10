import { Signer } from "ethers";

import { DynamicHoldingRevocableFromBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { storeDynamicFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDynamicHoldingRevocableFromBridge } from "../function/dynamic-holding-revocable-frombridge";

const network: Network = Network.LOCALHOST_8545;

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    
    const dynamicHoldingRevocableFromBridge: DynamicHoldingRevocableFromBridge =
        await deployDynamicHoldingRevocableFromBridge(deployer, validatorAddr);

    // Store
    storeDynamicFromBridge(network, dynamicHoldingRevocableFromBridge.address);

    // Log address
    console.log("Deployed DynamicHoldingRevocableFromBridge contract's address:");
    console.log(dynamicHoldingRevocableFromBridge.address);
})();
