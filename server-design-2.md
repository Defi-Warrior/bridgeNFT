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
```

#### STORED GLOBAL VALUE
```
n
commitKey[]
```

#### FUNCTION
###### SETUP ()
```
n <- 0
commitKey[n] <- random()
```

###### COMMIT_KEY_UPDATE ()
```
n <- n + 1
commitKey[n] <- random()
```

###### COMMIT (ownerAddr, tokenId, requestNonce)
```
secret <- PRF(commitKey[n], bridgeContext || ownerAddr || requestNonce)
commitment <- HASH(secret)
save(ownerAddr, tokenId, requestNonce, n)
return commitment
```

###### REVEAL (ownerAddr, tokenId, requestNonce)
```
i <- retrieve(ownerAddr, tokenId, requestNonce)
secret <- PRF(commitKey[i], bridgeContext || ownerAddr || requestNonce)
return secret
```

#### DATABASE (needed)
| ownerAddr | tokenId | requestNonce | usedKeyIndex |
| --------- | ------- | ------------ | ------------ |
| 0x1234... | 0       | 0            | 0            |
| 0x1234... | 0       | 1            | 1            |
| 0x1234... | 1       | 0            | 1            |
| 0x1234... | 1       | 1            | 2            |
| 0x1234... | 1       | 2            | 2            |
| 0x1234... | 2       | 0            | 0            |
| 0x5678... | 0       | 0            | 4            |
| ...       |         |              |              |
