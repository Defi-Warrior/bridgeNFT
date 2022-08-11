import { Signer } from "ethers";

import { DefiWarriorFromBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { FromTokenInfo } from "../../types/dto/token-info";
import { retrieveTokenInfoInFromData } from "../../utils/data/retrieve-token-info";
import { storeStaticFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDefiWarriorFromBridge } from "../function/defi-warrior-frombridge";

const network: NetworkInfo = NETWORK.BSC_TEST;
const fromTokenAddr: string = "";

(async () => {
    // Deploy.
    const deployer: Signer = getSigner(Role.DEPLOYER, network);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, network)).getAddress();
    const defiWarriorTokenInfo: FromTokenInfo = retrieveTokenInfoInFromData(network, fromTokenAddr);
    const fromBodyPartAddr: string = defiWarriorTokenInfo["BODYPART"];

    const defiWarriorFromBridge: DefiWarriorFromBridge =
        await deployDefiWarriorFromBridge(deployer, validatorAddr, fromTokenAddr, fromBodyPartAddr);
    
    // Store.
    storeStaticFromBridge(network, fromTokenAddr, defiWarriorFromBridge.address, true);

    // Log address.
    console.log("Deployed DefiWarriorFromBridge contract's address:");
    console.log(defiWarriorFromBridge.address);
})();
