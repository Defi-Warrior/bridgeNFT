####  SUMMARY
- Deterministic secrets from single commit key
- No database

#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
PRF := HMAC-SHA256
    PRF(key, message) -> pseudoRandomString

bridgeContext := {
    fromChainId, fromTokenAddr, fromBridgeAddr,
    toChainId, toTokenAddr, toBridgeAddr
}
bridgeRequestId := { bridgeContext, tokenOwner, requestNonce }
bridgeRequest   := { bridgeRequestId, tokenId }
```

#### STORED GLOBAL VALUE
```
secretGenKey
```

#### FUNCTION
###### SETUP ()
```
secretGenKey <- random()
```

###### VERIFY (bridgeRequest, signature)
```
if not SIG_VERIFY(tokenOwner, bridgeContext || requestNonce || tokenId, signature) then
    abort
```

###### COMMIT (bridgeRequest, signature)
```
VERIFY(bridgeRequest, signature)
secret <- PRF(secretGenKey, bridgeRequestId)
commitment <- HASH(secret)
return commitment
```

###### REVEAL (bridgeRequestId)
```
secret <- PRF(secretGenKey, bridgeRequestId)
return secret
```

#### DATABASE (not needed)
| bridgeRequestId | usedKey      | secret                 |
| --------------- | ------------ | ---------------------- |
| ...             | secretGenKey | (deterministic secret) |
|                 | secretGenKey | (deterministic secret) |
|                 | secretGenKey | (deterministic secret) |
|                 | secretGenKey | (deterministic secret) |
|                 | secretGenKey | (deterministic secret) |
|                 | secretGenKey | (deterministic secret) |
|                 | secretGenKey | (deterministic secret) |
|                 |              |                        |
