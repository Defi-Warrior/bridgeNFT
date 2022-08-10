import { Signer } from "ethers";

import { ToNftToBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { ToTokenInfo } from "../../types/dto/token-info";
import { retrieveTokenInfoInToData } from "../../utils/data/retrieve-token-info";
import { deployConfig } from "../../utils/config";
import { storeToBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployToNftToBridge } from "../function/_tonft-tobridge";

const network: Network = Network.LOCALHOST_8546;
const toTokenName: string = "ToNFT";

(async () => {
    // Deploy
    const deployer:         Signer = await getSigner(Role.DEPLOYER, network);
    const validatorAddr:    string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    const denierAddr:       string = await (await getSigner(Role.DENIER, network)).getAddress();
    const toTokenInfo: ToTokenInfo = retrieveTokenInfoInToData(network, toTokenName);
    const toTokenAddr:      string = toTokenInfo["ADDRESS"];

    const toNftToBridge: ToNftToBridge = await deployToNftToBridge(
        deployer,
        toTokenAddr,
        validatorAddr,
        denierAddr,
        deployConfig);

    // Store
    storeToBridge(network, toTokenName, toNftToBridge.address);

    // Log address
    console.log("Deployed ToNftToBridge contract's address:");
    console.log(toNftToBridge.address);
})();
