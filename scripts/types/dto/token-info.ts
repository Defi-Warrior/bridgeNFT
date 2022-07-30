export type FromTokenInfo = { ADDRESS: string, [key: string]: any } & (
    { DYNAMIC_FROMBRIDGE_COMPATIBILITY: true } |
    { DYNAMIC_FROMBRIDGE_COMPATIBILITY: false, STATIC_FROMBRIDGE: string }
);

export type ToTokenInfo = {
    ADDRESS: string,
    TOBRIDGE?: string
    [key: string]: any
};
