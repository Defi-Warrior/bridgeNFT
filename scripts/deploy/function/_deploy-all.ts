import { Signer } from "ethers";

import { DynamicBurningRevocableFromBridge, FromNFT, ToNftToBridge, ToNFT } from "../../../typechain-types";

import Network from "../../types/network-enum";
import { deployConfig } from "../../utils/config";
import { storeTokenInFromData, storeTokenInToData } from "../../utils/data/store-deployed-token";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployFromNFT } from "../function/_fromnft";
import { deploy as deployToNFT } from "../function/_tonft";
import { deploy as deployDynamicBurningRevocableFromBridge } from "./dynamic-burning-revocable-frombridge";
import { deploy as deployToNftToBridge } from "./_tonft-tobridge";
import { storeDynamicFromBridge, storeToBridge } from "../../utils/data/store-deployed-bridge";

export default async function deployAll(fromNetwork: Network, toNetwork: Network) {
    // Deploy "from" NFT and bridge.
    const fromDeployer: Signer = await getSigner(Role.DEPLOYER, fromNetwork);
    const validatorAddr: string = await (await getSigner(Role.VALIDATOR, fromNetwork)).getAddress();
    
    const fromToken: FromNFT = await deployFromNFT(fromDeployer);
    const dynamicBurningRevocableFromBridge: DynamicBurningRevocableFromBridge =
        await deployDynamicBurningRevocableFromBridge(fromDeployer, validatorAddr);
    
    // Deploy "to" NFT and bridge.
    const toDeployer: Signer = await getSigner(Role.DEPLOYER, toNetwork);
    const denierAddr: string = await (await getSigner(Role.DENIER, toNetwork)).getAddress();
    
    const toToken: ToNFT = await deployToNFT(toDeployer);
    const toNftToBridge: ToNftToBridge = await deployToNftToBridge(
        toDeployer,
        toToken.address,
        validatorAddr,
        denierAddr,
        deployConfig);

    // Store tokens
    let fromTokenName = await fromToken.name();
    let toTokenName = await toToken.name();
    storeTokenInFromData(fromNetwork, fromTokenName, fromToken.address);
    storeTokenInToData(toNetwork, toTokenName, toToken.address);
    
    // Store bridges
    storeDynamicFromBridge(fromNetwork, fromTokenName);
    storeToBridge(toNetwork, toTokenName, toNftToBridge.address);

    // Log address
    console.log("Deployed FromNFT contract's address:");
    console.log(fromToken.address);

    console.log("Deployed ToNFT contract's address:");
    console.log(toToken.address);

    console.log("Deployed DynamicBurningRevocableFromBridge contract's address:");
    console.log(dynamicBurningRevocableFromBridge.address);

    console.log("Deployed ToNftToBridge contract's address:");
    console.log(toNftToBridge.address);
}
