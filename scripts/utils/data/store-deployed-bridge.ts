import { NetworkInfo } from "../../types/dto/network-info";
import { FromTokenInfo, ToTokenInfo } from "../../types/dto/token-info";
import { retrieveFromData, retrieveToData, storeFromData, storeToData } from "./env-io";

export function storeDynamicBurningFromBridge(
    network: NetworkInfo,
    dynamicBurningFromBridgeAddr: string,
    isRevocable: boolean
) {
    const fromData = retrieveFromData();

    if (fromData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }

    fromData[String(network.CHAIN_ID)]["DYNAMIC_BURNING_FROMBRIDGE"] = {
        ADDRESS: dynamicBurningFromBridgeAddr,
        VALIDATOR_REVOCABILITY: isRevocable
    };

    storeFromData(fromData);
}

export function storeDynamicHoldingFromBridge(
    network: NetworkInfo,
    dynamicHoldingFromBridgeAddr: string,
    isRevocable: boolean
) {
    const fromData = retrieveFromData();

    if (fromData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }

    fromData[String(network.CHAIN_ID)]["DYNAMIC_HOLDING_FROMBRIDGE"] = {
        ADDRESS: dynamicHoldingFromBridgeAddr,
        VALIDATOR_REVOCABILITY: isRevocable
    };

    storeFromData(fromData);
}

export function storeStaticFromBridge(
    network: NetworkInfo,
    fromTokenAddr: string,
    staticFromBridgeAddr: string,
    isRevocable: boolean
) {
    const fromData = retrieveFromData();

    if (fromData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }
    const fromTokenInfo: FromTokenInfo = fromData[String(network.CHAIN_ID)]["TOKENS"][fromTokenAddr];
    if (fromTokenInfo == undefined) {
        throw("Token with address " + fromTokenAddr + " does not exist in 'from' data");
    }

    fromTokenInfo["DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY"] = false;
    fromTokenInfo["DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY"] = false;
    fromTokenInfo["STATIC_FROMBRIDGE"] = {
        ADDRESS: staticFromBridgeAddr,
        VALIDATOR_REVOCABILITY: isRevocable
    };

    storeFromData(fromData);
}

export function storeToBridge(
    network: NetworkInfo,
    toTokenAddr: string,
    toBridgeAddr: string,
    supportClaim: boolean,
    isRevocable: boolean
) {
    const toData = retrieveToData();

    if (toData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }
    const toTokenInfo: ToTokenInfo = toData[String(network.CHAIN_ID)]["TOKENS"][toTokenAddr];
    if (toTokenInfo == undefined) {
        throw("Token with address " + toTokenAddr + " does not exist in 'to' data");
    }

    toTokenInfo["TOBRIDGE"] = {
        ADDRESS: toBridgeAddr,
        SUPPORT_CLAIM: supportClaim,
        VALIDATOR_REVOCABILITY: isRevocable
    };

    storeToData(toData);
}
