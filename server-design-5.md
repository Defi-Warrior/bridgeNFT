####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Need to update commit key
- No database
- Support multiple servers
- Owner authentication using random challenge
#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
PRF := HMAC-SHA256
    PRF(key, message) -> pseudoRandomString
AEAD := XChaCha20-Poly1305
    AEAD_ENC(key, plaintext, associatedData) -> ciphertext (random)
    AEAD_DEC(key, ciphertext, associatedData) -> plaintext
MAC := HMAC-SHA256
    MAC_SIGN(key, message) -> tag
    MAC_VERIFY(key, message, tag) -> boolean
SIG := ECDSA
    SIG_SIGN(privateKey, message) -> signature
    SIG_VERIFY(publicKey, message, signature) -> boolean
```

#### STORED GLOBAL VALUE
```
n
commitKey[]
indexEncKey
challengeMacKey
challengeLifetime
```

#### FUNCTION
###### SETUP (init_commitKey, init_indexEncKey, init_challengeMacKey, init_challengeLifetime)
```
n <- 0
commitKey[n] <- init_commitKey
indexEncKey <- init_indexEncKey
challengeMacKey <- init_challengeMacKey
challengeLifetime <- init_challengeLifetime
```

###### COMMIT_KEY_UPDATE (new_commitKey)
```
n <- n + 1
commitKey[n] <- new_commitKey
```

###### AUTHENTICATE_CHALLENGE ()
```
timestamp <- now()
challenge <- random()
tag <- MAC_SIGN(challengeMacKey, timestamp || challenge)
return (timestamp, challenge, tag)
```

###### AUTHENTICATE_VERIFY (publicKey, tokenId, requestNonce, timestamp, challenge, tag, signature)
```
if not (timestamp < now() < timestamp + challengeLifetime) then
    abort
if not MAC_VERIFY(challengeMacKey, timestamp || challenge, tag) then
    abort
if not SIG_VERIFY(publicKey, tokenId || requestNonce || challenge, signature) then
    abort
```

###### COMMIT (ownerAddr, tokenId, requestNonce, timestamp, challenge, tag, signature)
```
AUTHENTICATE_VERIFY(ownerAddr, tokenId, requestNonce, timestamp, challenge, tag, signature)
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
