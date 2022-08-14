import { Signer } from "ethers";

import { DynamicHoldingRevocableFromBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { storeDynamicHoldingFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDynamicHoldingRevocableFromBridge } from "../function/dynamic-holding-revocable-frombridge";

const fromNetwork: NetworkInfo = NETWORK.LOCALHOST_8545;

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, fromNetwork)).getAddress();
    
    const dynamicHoldingRevocableFromBridge: DynamicHoldingRevocableFromBridge =
        await deployDynamicHoldingRevocableFromBridge(deployer, validatorAddr, fromNetwork);

    // Store.
    storeDynamicHoldingFromBridge(fromNetwork, dynamicHoldingRevocableFromBridge.address, true);

    // Log address.
    console.log("Deployed DynamicHoldingRevocableFromBridge contract's address:");
    console.log(dynamicHoldingRevocableFromBridge.address);
})();
