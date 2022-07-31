import { Signer } from "ethers";

import { FromBridge } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { retrieveTokenInfoInFromData } from "../../utils/data/retrieve-token-info";
import { storeStaticFromBridge } from "../../utils/data/store-deployed-bridge";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployStaticFromBridge, initialize as initializeStaticFromBridge } from "../function/static-frombridge";

const network: Network = Network.LOCALHOST_8545;
const fromTokenName: string = "FromNFT";
const toTokenAddr: string   = "0x0000000000000000000000000000000000000000";
const toBridgeAddr: string  = "0x0000000000000000000000000000000000000000";

(async () => {
    // Deploy
    const deployer: Signer = await getSigner(Role.DEPLOYER, network);
    const staticFromBridge: FromBridge = await deployStaticFromBridge(deployer);
    
    // Initialize
    const fromTokenAddr = retrieveTokenInfoInFromData(network, fromTokenName)["ADDRESS"];
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, network)).getAddress();
    await initializeStaticFromBridge(staticFromBridge, deployer, fromTokenAddr, toTokenAddr, toBridgeAddr, validatorAddr);

    // Store
    storeStaticFromBridge(network, fromTokenName, staticFromBridge.address);

    // Log address
    console.log("Deployed StaticFromBridge contract's address:");
    console.log(staticFromBridge.address);
})();
