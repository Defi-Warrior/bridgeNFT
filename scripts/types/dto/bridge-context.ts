import fs from "fs";

export default class BridgeContext {
    readonly fromTokenAddr: string;
    readonly fromBridgeAddr: string;
    readonly toTokenAddr: string;
    readonly toBridgeAddr: string;
    readonly validatorAddr: string;

    public constructor(
        fromTokenAddr: string, fromBridgeAddr: string,
        toTokenAddr: string, toBridgeAddr: string,
        validatorAddr: string
    ) {
        this.fromTokenAddr = fromTokenAddr;
        this.fromBridgeAddr = fromBridgeAddr;
        this.toTokenAddr = toTokenAddr;
        this.toBridgeAddr = toBridgeAddr;
        this.validatorAddr = validatorAddr;
    }

    public static readFromJson(filePath: string): BridgeContext | undefined {
        try {
            return JSON.parse(fs.readFileSync(filePath, "utf8"));
        } catch (err) {
            console.error(err);
        }
    }

    public writeToJson(filePath: string) {
        try {
            fs.writeFileSync(filePath, JSON.stringify(this));
        } catch (err) {
            console.error(err);
        }
    }
};
