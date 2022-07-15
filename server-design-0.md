####  SUMMARY
- Random secrets
- Need database
#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
```

#### FUNCTION
###### COMMIT (ownerAddr, tokenId, requestNonce)
```
secret <- random()
commitment <- HASH(secret)
save(ownerAddr, tokenId, requestNonce, secret)
return commitment
```

###### REVEAL (ownerAddr, tokenId, requestNonce)
```
secret <- retrieve(ownerAddr, tokenId, requestNonce)
return secret
```

#### DATABASE (needed)
| ownerAddr | tokenId | requestNonce | secret          |
| --------- | ------- | ------------ | --------------- |
| 0x1234... | 0       | 0            | (random secret) |
| 0x1234... | 0       | 1            | (random secret) |
| 0x1234... | 1       | 0            | (random secret) |
| 0x1234... | 1       | 1            | (random secret) |
| 0x1234... | 1       | 2            | (random secret) |
| 0x1234... | 2       | 0            | (random secret) |
| 0x5678... | 0       | 0            | (random secret) |
| ...       |         |              |                 |
