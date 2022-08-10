import { NetworkInfo } from "../../types/dto/network-info";
import { FromTokenInfo, ToTokenInfo } from "../../types/dto/token-info";
import { retrieveNetworkBridgeInfoInFromData, retrieveNetworkBridgeInfoInToData } from "./retrieve-network-bridge-info";

export function retrieveTokenInfoInFromData(network: NetworkInfo, fromTokenAddr: string): FromTokenInfo {
    const fromTokenInfo: FromTokenInfo = retrieveNetworkBridgeInfoInFromData(network)["TOKENS"][fromTokenAddr];

    if (fromTokenInfo == undefined) {
        throw("Token with address " + fromTokenAddr + " does not exist in 'from' data");
    }

    return fromTokenInfo;
}

export function retrieveTokenInfoInToData(network: NetworkInfo, toTokenAddr: string): ToTokenInfo {
    const toTokenInfo: ToTokenInfo = retrieveNetworkBridgeInfoInToData(network)["TOKENS"][toTokenAddr];

    if (toTokenInfo == undefined) {
        throw("Token with address " + toTokenAddr + " does not exist in 'to' data");
    }

    return toTokenInfo;
}
