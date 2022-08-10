import { FromBridgeInfo, ToBridgeInfo } from "./bridge-info";

export type FromTokenInfo = { NAME: string, [key: string]: any } & (
    { DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY: true, DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY: true } |
    // There is no
    // { DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY: true, DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY: false } |
    // because compatibility with BurningFromBridge leads to compatibility with HoldingFromBridge.
    { DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY: false, DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY: true } |
    { DYNAMIC_BURNING_FROMBRIDGE_COMPATIBILITY: false, DYNAMIC_HOLDING_FROMBRIDGE_COMPATIBILITY: false, STATIC_FROMBRIDGE?: FromBridgeInfo }
);

export type ToTokenInfo = {
    NAME: string,
    TOBRIDGE?: ToBridgeInfo,
    [key: string]: any
};
