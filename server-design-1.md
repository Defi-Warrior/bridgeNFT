####  SUMMARY
- Deterministic secrets from single commit key
- No database

#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
PRF := HMAC-SHA256
    PRF(key, message) -> pseudoRandomString
```

#### STORED GLOBAL VALUE
```
commitKey
```

#### FUNCTION
###### SETUP ()
```
commitKey <- random()
```

###### COMMIT (ownerAddr, tokenId, requestNonce)
```
secret <- PRF(commitKey, ownerAddr || tokenId || requestNonce)
commitment <- HASH(secret)
return commitment
```

###### REVEAL (ownerAddr, tokenId, requestNonce)
```
secret <- PRF(commitKey, ownerAddr || tokenId || requestNonce)
return secret
```

#### DATABASE (not needed)
| ownerAddr | tokenId | requestNonce | usedKey   | secret                 |
| --------- | ------- | ------------ | --------- | ---------------------- |
| 0x1234... | 0       | 0            | commitKey | (deterministic secret) |
| 0x1234... | 0       | 1            | commitKey | (deterministic secret) |
| 0x1234... | 1       | 0            | commitKey | (deterministic secret) |
| 0x1234... | 1       | 1            | commitKey | (deterministic secret) |
| 0x1234... | 1       | 2            | commitKey | (deterministic secret) |
| 0x1234... | 2       | 0            | commitKey | (deterministic secret) |
| 0x5678... | 0       | 0            | commitKey | (deterministic secret) |
| ...       |         |              |           |                        |
