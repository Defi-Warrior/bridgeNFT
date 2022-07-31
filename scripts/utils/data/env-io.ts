import fs from "fs";

import ENV from "../../../env"

function readJson(srcFilePath: string): Record<string, any> {
    return JSON.parse(fs.readFileSync(srcFilePath, "utf8"));
}

function writeJson(desFilePath: string, obj: Record<string, any>) {
    fs.writeFileSync(desFilePath, JSON.stringify(obj));
}

const networkFilePath: string = __dirname + "/../../../env/" + ENV + "/networks.json";
export function retrieveNetworkInfo(): Record<string, any> {
    return readJson(networkFilePath);
}

const fromFilePath: string = __dirname + "/../../../env/" + ENV + "/from.json";
export function retrieveFromData(): Record<string, any> {
    return readJson(fromFilePath);
}
export function storeFromData(obj: Record<string, any>) {
    return writeJson(fromFilePath, obj);
}

const toFilePath: string = __dirname + "/../../../env/" + ENV + "/to.json";
export function retrieveToData(): Record<string, any> {
    return readJson(toFilePath);
}
export function storeToData(obj: Record<string, any>) {
    return writeJson(toFilePath, obj);
}
