import { Signer } from "ethers";

import { DefiWarriorFromBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { FromTokenInfo } from "../../types/dto/token-info";
import { retrieveTokenInfoInFromData } from "../../utils/data/retrieve-token-info";
import { storeStaticFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDefiWarriorFromBridge } from "../function/defi-warrior-frombridge";

const network: Network = Network.BSC;
const fromTokenName: string = "Defi Warrior NFT";

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    const defiWarriorTokenInfo: FromTokenInfo = retrieveTokenInfoInFromData(network, fromTokenName);
    const fromTokenAddr: string = defiWarriorTokenInfo["ADDRESS"];
    const fromBodyPartAddr: string = defiWarriorTokenInfo["Defi Warrior BodyPart NFT"];

    const defiWarriorFromBridge: DefiWarriorFromBridge =
        await deployDefiWarriorFromBridge(deployer, validatorAddr, fromTokenAddr, fromBodyPartAddr);
    
    // Store
    storeStaticFromBridge(network, fromTokenName, defiWarriorFromBridge.address);

    // Log address
    console.log("Deployed DefiWarriorFromBridge contract's address:");
    console.log(defiWarriorFromBridge.address);
})();
