####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Support update commit key
- No database

#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
PRF := HMAC-SHA256
    PRF(key, message) -> pseudoRandomString
AEAD := XChaCha20-Poly1305
    AEAD_ENC(key, plaintext, associatedData) -> ciphertext (random)
    AEAD_DEC(key, ciphertext, associatedData) -> plaintext

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
indexEncKey
```

#### FUNCTION
###### SETUP ()
```
n <- 0
secretGenKey[n] <- random()
indexEncKey <- random()
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
keyIndicator <- AEAD_ENC(indexEncKey, n, bridgeRequestId)
return (commitment, keyIndicator)
```

###### REVEAL (bridgeRequestId, keyIndicator)
```
i <- AEAD_DEC(indexEncKey, keyIndicator, bridgeRequestId)
secret <- PRF(secretGenKey[i], bridgeRequestId)
return secret
```

#### DATABASE (not needed)
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
