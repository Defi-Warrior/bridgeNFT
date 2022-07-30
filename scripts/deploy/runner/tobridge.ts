import { Signer } from "ethers";

import { ToBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { retrieveTokenInfoInToData } from "../../utils/data/retrieve-token-info";
import { deployConfig } from "../../utils/config";
import { storeToBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployToBridge, initialize as initializeToBridge } from "../function/tobridge";

const network: Network = Network.LOCALHOST_8546;
const fromTokenAddr: string   = "0x0000000000000000000000000000000000000000";
const fromBridgeAddr: string  = "0x0000000000000000000000000000000000000000";
const toTokenName: string = "ToNFT";

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const toBridge: ToBridge = await deployToBridge(deployer);
    
    // Initialize
    const toTokenAddr = retrieveTokenInfoInToData(network, toTokenName)["ADDRESS"];
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    await initializeToBridge(toBridge, deployer, fromTokenAddr, fromBridgeAddr, toTokenAddr, validatorAddr, deployConfig);

    // Store
    storeToBridge(network, toTokenName, toBridge.address);

    // Log address
    console.log("Deployed ToBridge contract's address:");
    console.log(toBridge.address);
})();
