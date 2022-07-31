import Network from "../../types/network-enum";
import { retrieveFromData, retrieveToData, storeFromData, storeToData } from "./env-io";

export function storeTokenInFromData(
    network: Network,
    tokenName: string,
    tokenAddr: string,
    isDynamicFromBridgeCompatible: boolean = true
) {
    const fromData: Record<string, any> = retrieveFromData();

    if (fromData[network] == undefined) {
        throw(network + " is not supported");
    }

    if (isDynamicFromBridgeCompatible) {
        fromData[network]["TOKENS"][tokenName] = {
            ADDRESS: tokenAddr,
            DYNAMIC_FROMBRIDGE_COMPATIBILITY: true
        }
    } else {
        fromData[network]["TOKENS"][tokenName] = {
            ADDRESS: tokenAddr,
            DYNAMIC_FROMBRIDGE_COMPATIBILITY: false,
            STATIC_FROMBRIDGE: ""
        }
    }

    storeFromData(fromData);
}

export function storeTokenInToData(
    network: Network,
    tokenName: string,
    tokenAddr: string,
    toBridgeAddr?: string
) {
    const toData: Record<string, any> = retrieveToData();

    if (toData[network] == undefined) {
        throw(network + " is not supported");
    }

    if (toBridgeAddr == undefined) {
        toData[network]["TOKENS"][tokenName] = {
            ADDRESS: tokenAddr
        }
    } else {
        toData[network]["TOKENS"][tokenName] = {
            ADDRESS: tokenAddr,
            TOBRIDGE: toBridgeAddr
        }
    }

    storeToData(toData);
}
