import { NetworkInfo } from "../../types/dto/network-info";
import { FromTokenInfo, ToTokenInfo } from "../../types/dto/token-info";
import { retrieveNetworkBridgeInfoInFromData } from "./retrieve-network-bridge-info";
import { FromNetworkBridgeInfo } from "../../types/dto/network-bridge-info";
import { retrieveTokenInfoInToData } from "./retrieve-token-info";

export function retrieveFromBridgeAddress(network: NetworkInfo, fromTokenAddr: string): string {
    const fromNetworkBridgeInfo: FromNetworkBridgeInfo = retrieveNetworkBridgeInfoInFromData(network);
    const fromTokenInfo: FromTokenInfo = fromNetworkBridgeInfo["TOKENS"][fromTokenAddr];
    if (fromTokenInfo == undefined) {
        throw("Token with address " + fromTokenAddr + " does not exist in 'from' data");
    }

    if (fromTokenInfo["DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY"]) {
        return fromNetworkBridgeInfo["DYNAMIC_BURNING_FROMBRIDGE"]["ADDRESS"];
    }
    if (fromTokenInfo["DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY"]) {
        return fromNetworkBridgeInfo["DYNAMIC_HOLDING_FROMBRIDGE"]["ADDRESS"];
    }
    if(fromTokenInfo["STATIC_FROMBRIDGE"] == undefined) {
        throw("StaticFromBridge is not available");
    }
    return fromTokenInfo["STATIC_FROMBRIDGE"]["ADDRESS"];
}

export function retrieveToBridgeAddress(network: NetworkInfo, toTokenAddr: string): string {
    const toTokenInfo: ToTokenInfo = retrieveTokenInfoInToData(network, toTokenAddr);
    
    if (toTokenInfo["TOBRIDGE"] == undefined) {
        throw("ToBridge is not available");
    }
    return toTokenInfo["TOBRIDGE"]["ADDRESS"];
}
