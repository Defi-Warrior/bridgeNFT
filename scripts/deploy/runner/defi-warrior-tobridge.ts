import { Signer } from "ethers";

import { DefiWarriorToBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { ToTokenInfo } from "../../types/dto/token-info";
import { retrieveTokenInfoInToData } from "../../utils/data/retrieve-token-info";
import { deployConfig } from "../../utils/config";
import { storeToBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDefiWarriorToBridge } from "../function/defi-warrior-tobridge";

const toNetwork: NetworkInfo = NETWORK.POLYGON_MAIN;
const toTokenAddr: string = "";

(async () => {
    // Deploy.
    const deployer:         Signer = getSigner(Role.DEPLOYER, toNetwork);
    const validatorAddr:    string = await (getSigner(Role.VALIDATOR, toNetwork)).getAddress();
    const denierAddr:       string = await (getSigner(Role.DENIER, toNetwork)).getAddress();
    const toTokenInfo: ToTokenInfo = retrieveTokenInfoInToData(toNetwork, toTokenAddr);
    const nftManagerAddr:   string = toTokenInfo["NFT_MANAGER"];

    const defiWarriorToBridge: DefiWarriorToBridge = await deployDefiWarriorToBridge(
        deployer,
        toTokenAddr,
        validatorAddr,
        denierAddr,
        deployConfig,
        nftManagerAddr,
        toNetwork);

    // Store.
    storeToBridge(toNetwork, toTokenAddr, defiWarriorToBridge.address, true, true);

    // Log address.
    console.log("Deployed DefiWarriorToBridge contract's address:");
    console.log(defiWarriorToBridge.address);
})();
