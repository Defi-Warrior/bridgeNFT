import { Signer } from "ethers";

import { FromBridge, FromNFT, ToBridge, ToNFT } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { deployConfig } from "../../utils/config";
import { storeTokenInFromData, storeTokenInToData } from "../../utils/data/store-deployed-token";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployFromNFT } from "../function/_fromnft";
import { deploy as deployToNFT, initialize as initializeToNFT } from "../function/_tonft";
import { deploy as deployStaticFromBridge, initialize as initializeStaticFromBridge } from "../function/static-frombridge";
import { deploy as deployToBridge, initialize as initializeToBridge } from "../function/tobridge";
import { storeStaticFromBridge, storeToBridge } from "../../utils/data/store-deployed-bridge";

export default async function deployAll(fromNetwork: Network, toNetwork: Network) {
    // Deploy
    const fromDeployer: Signer = await getSigner(Role.DEPLOYER, fromNetwork);
    const fromToken: FromNFT = await deployFromNFT(fromDeployer);
    const staticFromBridge: FromBridge = await deployStaticFromBridge(fromDeployer);
    
    const toDeployer: Signer = await getSigner(Role.DEPLOYER, toNetwork);
    const toToken: ToNFT = await deployToNFT(toDeployer);
    const toBridge: ToBridge = await deployToBridge(toDeployer);

    // Store tokens
    let fromTokenName = await fromToken.name();
    let toTokenName = await toToken.name();
    storeTokenInFromData(fromNetwork, fromTokenName, fromToken.address);
    storeTokenInToData(toNetwork, toTokenName, toToken.address);
    
    // Initialize
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, fromNetwork)).getAddress();
    await initializeStaticFromBridge(staticFromBridge, fromDeployer, fromToken.address, toToken.address, toBridge.address, validatorAddr);
    await initializeToBridge(toBridge, toDeployer, fromToken.address, staticFromBridge.address, toToken.address, validatorAddr, deployConfig);
    await initializeToNFT(toToken, toDeployer, toBridge.address);
    
    // Store bridges
    storeStaticFromBridge(fromNetwork, fromTokenName, staticFromBridge.address);
    storeToBridge(toNetwork, toTokenName, toBridge.address);

    // Log address
    console.log("Deployed FromNFT contract's address:");
    console.log(fromToken.address);

    console.log("Deployed ToNFT contract's address:");
    console.log(toToken.address);

    console.log("Deployed StaticFromBridge contract's address:");
    console.log(staticFromBridge.address);

    console.log("Deployed ToBridge contract's address:");
    console.log(toBridge.address);
}
