import Network from "../../types/network-enum";
import { retrieveFromData } from "./env-io";

export function retrieveDynamicFromBridge(network: Network): string {
    const fromData: Record<string, any> = retrieveFromData();

    if (fromData[network] == undefined) {
        throw(network + " is not supported");
    }
    const dynamicFromBridgeAddr: string = fromData[network]["DYNAMIC_FROMBRIDGE"];
    if (dynamicFromBridgeAddr == undefined) {
        throw("Dynamic FromBridge is not available");
    }

    return dynamicFromBridgeAddr;
}
