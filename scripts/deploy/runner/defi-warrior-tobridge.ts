import { Signer } from "ethers";

import { DefiWarriorToBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { ToTokenInfo } from "../../types/dto/token-info";
import { retrieveTokenInfoInToData } from "../../utils/data/retrieve-token-info";
import { deployConfig } from "../../utils/config";
import { storeToBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployDefiWarriorToBridge } from "../function/defi-warrior-tobridge";

const network: Network = Network.POLYGON;
const toTokenName: string = "Defi Warrior NFT";

(async () => {
    // Deploy
    const deployer:         Signer = await getSigner(Role.DEPLOYER, network);
    const validatorAddr:    string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    const denierAddr:       string = await (await getSigner(Role.DENIER, network)).getAddress();
    const toTokenInfo: ToTokenInfo = retrieveTokenInfoInToData(network, toTokenName);
    const toTokenAddr:      string = toTokenInfo["ADDRESS"];
    const nftManagerAddr:   string = toTokenInfo["NFT_MANAGER"];

    const defiWarriorToBridge: DefiWarriorToBridge = await deployDefiWarriorToBridge(
        deployer,
        toTokenAddr,
        validatorAddr,
        denierAddr,
        deployConfig,
        nftManagerAddr);

    // Store
    storeToBridge(network, toTokenName, defiWarriorToBridge.address);

    // Log address
    console.log("Deployed DefiWarriorToBridge contract's address:");
    console.log(defiWarriorToBridge.address);
})();
