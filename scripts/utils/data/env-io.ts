import fs from "fs";

import { FromNetworkBridgeInfo, ToNetworkBridgeInfo } from "../../types/dto/network-bridge-info";

import ENV from "../../../env"

function readJson(srcFilePath: string): Record<string, any> {
    return JSON.parse(fs.readFileSync(srcFilePath, "utf8"));
}

function writeJson(desFilePath: string, obj: Record<string, any>) {
    fs.writeFileSync(desFilePath, JSON.stringify(obj));
}

const fromFilePath: string = __dirname + "/../../../env/" + ENV + "/from.json";
export function retrieveFromData(): {
    [chainId: string]: FromNetworkBridgeInfo
} {
    return readJson(fromFilePath);
}
export function storeFromData(
    obj: {
        [chainId: string]: FromNetworkBridgeInfo
    }
) {
    return writeJson(fromFilePath, obj);
}

const toFilePath: string = __dirname + "/../../../env/" + ENV + "/to.json";
export function retrieveToData(): {
    [chainId: string]: ToNetworkBridgeInfo
} {
    return readJson(toFilePath);
}
export function storeToData(
    obj: {
        [chainId: string]: ToNetworkBridgeInfo
    }
) {
    return writeJson(toFilePath, obj);
}
