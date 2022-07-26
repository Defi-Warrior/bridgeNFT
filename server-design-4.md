####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Support update commit key
- No database
- Support multiple servers

#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
PRF := HMAC-SHA256
    PRF(key, message) -> pseudoRandomString
AEAD := XChaCha20-Poly1305
    AEAD_ENC(key, plaintext, associatedData) -> ciphertext (random)
    AEAD_DEC(key, ciphertext, associatedData) -> plaintext
```

#### STORED GLOBAL VALUE
```
n
commitKey[]
indexEncKey
```

#### FUNCTION
###### SETUP (init_commitKey, init_indexEncKey)
```
n <- 0
commitKey[n] <- init_commitKey
indexEncKey <- init_indexEncKey
```

###### COMMIT_KEY_UPDATE (new_commitKey)
```
n <- n + 1
commitKey[n] <- new_commitKey
```

###### COMMIT (ownerAddr, tokenId, requestNonce)
```
secret <- PRF(commitKey[n], ownerAddr || tokenId || requestNonce)
commitment <- HASH(secret)
keyIndicator <- AEAD_ENC(indexEncKey, n, ownerAddr || tokenId || requestNonce)
return (commitment, keyIndicator)
```

###### REVEAL (ownerAddr, tokenId, requestNonce, keyIndicator)
```
i <- AEAD_DEC(indexEncKey, keyIndicator, ownerAddr || tokenId || requestNonce)
secret <- PRF(commitKey[i], ownerAddr || tokenId || requestNonce)
return secret
```

#### DATABASE (not needed)
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
