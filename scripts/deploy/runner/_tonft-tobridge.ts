import { Signer } from "ethers";

import { ToNftToBridge } from "../../../typechain-types";

import { NETWORK } from "../../../env/network";
import { NetworkInfo } from "../../types/dto/network-info";
import { deployConfig } from "../../utils/config";
import { storeToBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployToNftToBridge } from "../function/_tonft-tobridge";

const network: NetworkInfo = NETWORK.LOCALHOST_8546;
const toTokenAddr: string = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

(async () => {
    // Deploy.
    const deployer:         Signer = getSigner(Role.DEPLOYER, network);
    const validatorAddr:    string = await (getSigner(Role.VALIDATOR, network)).getAddress();
    const denierAddr:       string = await (getSigner(Role.DENIER, network)).getAddress();

    const toNftToBridge: ToNftToBridge = await deployToNftToBridge(
        deployer,
        toTokenAddr,
        validatorAddr,
        denierAddr,
        deployConfig);

    // Store.
    storeToBridge(network, toTokenAddr, toNftToBridge.address, true, true);

    // Log address.
    console.log("Deployed ToNftToBridge contract's address:");
    console.log(toNftToBridge.address);
})();
