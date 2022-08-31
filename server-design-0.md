####  SUMMARY
- Random secrets
- Need database

#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest

bridgeContext := {
    fromChainId, fromTokenAddr, fromBridgeAddr,
    toChainId, toTokenAddr, toBridgeAddr
}
bridgeRequestId := { bridgeContext, tokenOwner, requestNonce }
bridgeRequest   := { bridgeRequestId, tokenId }
```

#### FUNCTION
###### VERIFY (bridgeRequest, signature)
```
if not SIG_VERIFY(tokenOwner, bridgeContext || requestNonce || tokenId, signature) then
    abort
```

###### COMMIT (bridgeRequest, signature)
```
VERIFY(bridgeRequest, signature)
secret <- random()
commitment <- HASH(secret)
save(bridgeRequestId, secret)
return commitment
```

###### REVEAL (bridgeRequestId)
```
secret <- retrieve(bridgeRequestId)
return secret
```

#### DATABASE (needed)
| bridgeContext | tokenOwner | requestNonce | secret          |
| ------------- | ---------- | ------------ | --------------- |
| ...           | 0x1234...  | 0            | (random secret) |
|               | 0x1234...  | 1            | (random secret) |
|               | 0x1234...  | 0            | (random secret) |
|               | 0x1234...  | 1            | (random secret) |
|               | 0x1234...  | 2            | (random secret) |
|               | 0x1234...  | 0            | (random secret) |
|               | 0x5678...  | 0            | (random secret) |
|               | ...        |              |                 |
