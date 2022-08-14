import { Signer } from "ethers";

import { DynamicBurningRevocableFromBridge, FromNFT, ToNftToBridge, ToNFT } from "../../../typechain-types";

import { NetworkInfo } from "../../types/dto/network-info";
import { deployConfig } from "../../utils/config";
import { storeTokenInFromData, storeTokenInToData } from "../../utils/data/store-deployed-token";
import { getSigner, Role } from "../../utils/get-signer";
import { deploy as deployFromNFT } from "../function/_fromnft";
import { deploy as deployToNFT } from "../function/_tonft";
import { deploy as deployDynamicBurningRevocableFromBridge } from "./dynamic-burning-revocable-frombridge";
import { deploy as deployToNftToBridge } from "./_tonft-tobridge";
import { storeDynamicBurningFromBridge, storeToBridge } from "../../utils/data/store-deployed-bridge";

export default async function deployAll(fromNetwork: NetworkInfo, toNetwork: NetworkInfo) {
    // Deploy "from" NFT and bridge.
    const fromDeployer: Signer = getSigner(Role.DEPLOYER, fromNetwork);
    const validatorAddr: string = await (getSigner(Role.VALIDATOR, fromNetwork)).getAddress();
    
    const fromToken: FromNFT = await deployFromNFT(fromDeployer, fromNetwork);
    const dynamicBurningRevocableFromBridge: DynamicBurningRevocableFromBridge =
        await deployDynamicBurningRevocableFromBridge(fromDeployer, validatorAddr, fromNetwork);
    
    // Deploy "to" NFT and bridge.
    const toDeployer: Signer = getSigner(Role.DEPLOYER, toNetwork);
    const denierAddr: string = await (getSigner(Role.DENIER, toNetwork)).getAddress();
    
    const toToken: ToNFT = await deployToNFT(toDeployer, toNetwork);
    const toNftToBridge: ToNftToBridge = await deployToNftToBridge(
        toDeployer,
        toToken.address,
        validatorAddr,
        denierAddr,
        deployConfig,
        toNetwork);

    // Set allow mint to bridge.
    await toToken.connect(toDeployer).setToBridge(toNftToBridge.address);
    await toToken.connect(toDeployer).setAllowMint(true);

    // Store tokens.
    storeTokenInFromData(fromNetwork, fromToken.address, {
        NAME: await fromToken.name(),
        DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY: true,
        DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY: true
    });
    storeTokenInToData(toNetwork, toToken.address, {
        NAME: await toToken.name()
    });
    
    // Store bridges.
    storeDynamicBurningFromBridge(fromNetwork, dynamicBurningRevocableFromBridge.address, true);
    storeToBridge(toNetwork, toToken.address, toNftToBridge.address, true, true);

    // Log address.
    console.log("Deployed FromNFT contract's address:");
    console.log(fromToken.address);

    console.log("Deployed ToNFT contract's address:");
    console.log(toToken.address);

    console.log("Deployed DynamicBurningRevocableFromBridge contract's address:");
    console.log(dynamicBurningRevocableFromBridge.address);

    console.log("Deployed ToNftToBridge contract's address:");
    console.log(toNftToBridge.address);
}
