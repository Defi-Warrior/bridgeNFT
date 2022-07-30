import { FromTokenInfo, ToTokenInfo } from "../../types/dto/token-info";
import Network from "../../types/network-enum";
import { retrieveFromData, retrieveToData } from "./env-io";

export function retrieveTokenInfoInFromData(network: Network, tokenName: string): FromTokenInfo {
    const fromData: Record<string, any> = retrieveFromData();

    if (fromData[network] == undefined) {
        throw(network + " is not supported");
    }
    const tokenInfo = fromData[network]["TOKENS"][tokenName];
    if (tokenInfo == undefined) {
        throw(tokenName + " does not exist in 'from' data");
    }

    return tokenInfo;
}

export function retrieveTokenInfoInToData(network: Network, tokenName: string): ToTokenInfo {
    const toData: Record<string, any> = retrieveToData();

    if (toData[network] == undefined) {
        throw(network + " is not supported");
    }
    const tokenInfo = toData[network]["TOKENS"][tokenName];
    if (tokenInfo == undefined) {
        throw(tokenName + " does not exist in 'to' data");
    }

    return tokenInfo;
}
