import { NetworkInfo } from "../../types/dto/network-info";
import { FromNetworkBridgeInfo, ToNetworkBridgeInfo } from "../../types/dto/network-bridge-info";
import { retrieveFromData, retrieveToData } from "./env-io";

export function retrieveNetworkBridgeInfoInFromData(network: NetworkInfo): FromNetworkBridgeInfo {
    const fromData = retrieveFromData();

    if (fromData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }

    return fromData[String(network.CHAIN_ID)];
}

export function retrieveNetworkBridgeInfoInToData(network: NetworkInfo): ToNetworkBridgeInfo {
    const toData = retrieveToData();

    if (toData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }
    
    return toData[String(network.CHAIN_ID)];
}
