import { Signer } from "ethers";

import { ToNftToBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { deployConfig } from "../../utils/config";
import { storeToBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployToNftToBridge } from "../function/_tonft-tobridge";

const toNetwork: NetworkInfo = NETWORK.LOCALHOST_8546;
const toTokenAddr: string = "";

(async () => {
    // Deploy.
    const deployer:         Signer = getSigner(Role.DEPLOYER, toNetwork);
    const validatorAddr:    string = await (getSigner(Role.VALIDATOR, toNetwork)).getAddress();
    const denierAddr:       string = await (getSigner(Role.DENIER, toNetwork)).getAddress();

    const toNftToBridge: ToNftToBridge = await deployToNftToBridge(
        deployer,
        toTokenAddr,
        validatorAddr,
        denierAddr,
        deployConfig,
        toNetwork);

    // Store.
    storeToBridge(toNetwork, toTokenAddr, toNftToBridge.address, true, true);

    // Log address.
    console.log("Deployed ToNftToBridge contract's address:");
    console.log(toNftToBridge.address);
})();
