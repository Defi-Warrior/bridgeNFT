import { Signer } from "ethers";

import { DefiWarriorFromBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { FromTokenInfo } from "../../types/dto/token-info";
import { retrieveTokenInfoInFromData } from "../../utils/data/retrieve-token-info";
import { storeStaticFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDefiWarriorFromBridge } from "../function/defi-warrior-frombridge";

const fromNetwork: NetworkInfo = NETWORK.BSC_TEST;
const fromTokenAddr: string = "";

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, fromNetwork)).getAddress();
    const defiWarriorTokenInfo: FromTokenInfo = retrieveTokenInfoInFromData(fromNetwork, fromTokenAddr);
    const fromBodyPartAddr: string = defiWarriorTokenInfo["BODYPART"];

    const defiWarriorFromBridge: DefiWarriorFromBridge =
        await deployDefiWarriorFromBridge(deployer, validatorAddr, fromTokenAddr, fromBodyPartAddr, fromNetwork);
    
    // Store.
    storeStaticFromBridge(fromNetwork, fromTokenAddr, defiWarriorFromBridge.address, true);

    // Log address.
    console.log("Deployed DefiWarriorFromBridge contract's address:");
    console.log(defiWarriorFromBridge.address);
})();
