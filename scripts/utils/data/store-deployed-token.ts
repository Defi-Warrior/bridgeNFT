import { NetworkInfo } from "../../types/dto/network-info";
import { FromTokenInfo, ToTokenInfo } from "../../types/dto/token-info";
import { retrieveFromData, retrieveToData, storeFromData, storeToData } from "./env-io";

export function storeTokenInFromData(
    network: NetworkInfo,
    fromTokenAddr: string,
    fromTokenInfo: FromTokenInfo
) {
    if (fromTokenInfo.DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY &&
        !fromTokenInfo.DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY) {
        throw("Token that is compatible with BurningFromBridge is automatically compatible with HoldingFromBridge");
    }
    if (!fromTokenInfo.DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY &&
        !fromTokenInfo.DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY &&
        fromTokenInfo.STATIC_FROMBRIDGE == undefined) {
        throw("StaticFromBridge for this token must be specified");
    }
    
    const fromData = retrieveFromData();

    if (fromData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }

    fromData[String(network.CHAIN_ID)]["TOKENS"][fromTokenAddr] = fromTokenInfo;

    storeFromData(fromData);
}

export function storeTokenInToData(
    network: NetworkInfo,
    toTokenAddr: string,
    toTokenInfo: ToTokenInfo
) {
    const toData = retrieveToData();

    if (toData[String(network.CHAIN_ID)] == undefined) {
        throw(network.NAME + " is not supported");
    }

    toData[String(network.CHAIN_ID)]["TOKENS"][toTokenAddr] = toTokenInfo;

    storeToData(toData);
}
