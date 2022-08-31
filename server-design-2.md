####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Support update commit key
- Need database

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
n
secretGenKey[]
```

#### FUNCTION
###### SETUP ()
```
n <- 0
secretGenKey[n] <- random()
```

###### SECRET_GEN_KEY_UPDATE ()
```
n <- n + 1
secretGenKey[n] <- random()
```

###### VERIFY (bridgeRequest, signature)
```
if not SIG_VERIFY(tokenOwner, bridgeContext || requestNonce || tokenId, signature) then
    abort
```

###### COMMIT (bridgeRequest, signature)
```
VERIFY(bridgeRequest, signature)
secret <- PRF(secretGenKey[n], bridgeRequestId)
commitment <- HASH(secret)
save(bridgeRequestId, n)
return commitment
```

###### REVEAL (bridgeRequestId)
```
i <- retrieve(bridgeRequestId)
secret <- PRF(secretGenKey[i], bridgeRequestId)
return secret
```

#### DATABASE (needed)
| bridgeRequestId | usedKeyIndex |
| --------------- | ------------ |
| ...             | 0            |
|                 | 1            |
|                 | 1            |
|                 | 2            |
|                 | 2            |
|                 | 0            |
|                 | 4            |
|                 |              |
