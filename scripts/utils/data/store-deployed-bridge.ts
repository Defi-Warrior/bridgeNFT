import Network from "../../types/network-enum";
import { retrieveFromData, retrieveToData, storeFromData, storeToData } from "./env-io";

export function storeDynamicFromBridge(
    network: Network,
    dynamicFromBridgeAddr: string
) {
    const fromData: Record<string, any> = retrieveFromData();

    if (fromData[network] == undefined) {
        throw(network + " is not supported");
    }

    fromData[network]["DYNAMIC_FROMBRIDGE"] = dynamicFromBridgeAddr;

    storeFromData(fromData);
}

export function storeStaticFromBridge(
    network: Network,
    tokenName: string,
    staticFromBridgeAddr: string
) {
    const fromData: Record<string, any> = retrieveFromData();

    if (fromData[network] == undefined) {
        throw(network + " is not supported");
    }
    if (fromData[network]["TOKENS"][tokenName] == undefined) {
        throw(tokenName + " does not exist in 'from' data");
    }

    fromData[network]["TOKENS"][tokenName]["DYNAMIC_FROMBRIDGE_COMPATIBILITY"] = false;
    fromData[network]["TOKENS"][tokenName]["STATIC_FROMBRIDGE"] = staticFromBridgeAddr;

    storeFromData(fromData);
}

export function storeToBridge(
    network: Network,
    tokenName: string,
    toBridgeAddr: string
) {
    const toData: Record<string, any> = retrieveToData();

    if (toData[network] == undefined) {
        throw(network + " is not supported");
    }
    if (toData[network]["TOKENS"][tokenName] == undefined) {
        throw(tokenName + " does not exist in 'to' data");
    }

    toData[network]["TOKENS"][tokenName]["TOBRIDGE"] = toBridgeAddr;

    storeToData(toData);
}
