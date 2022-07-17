####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Support update commit key
- No database
- Support multiple servers
- Owner authentication using challenge generated from PRF
- Generate challenge periodically

#### DEFINE
```
HASH := Keccak256
    HASH(message) -> digest
PRF := HMAC-SHA256
    PRF(key, message) -> pseudoRandomString
AEAD := XChaCha20-Poly1305
    AEAD_ENC(key, plaintext, associatedData) -> ciphertext (random)
    AEAD_DEC(key, ciphertext, associatedData) -> plaintext
SIG := ECDSA
    SIG_SIGN(privateKey, message) -> signature
    SIG_VERIFY(publicKey, message, signature) -> boolean
```

#### STORED GLOBAL VALUE
```
n
commitKey[]
indexEncKey
challengeGenKey
challengeLifetime
challengeGenPeriod (< challengeLifetime)
lastChallengeGenTimestamp
```

#### FUNCTION
###### SETUP (init_commitKey, init_indexEncKey, init_challengeGenKey, init_challengeLifetime, init_ challengeGenPeriod, init_lastChallengeGenTimestamp)
```
n <- 0
commitKey[n] <- init_commitKey
indexEncKey <- init_indexEncKey
challengeGenKey <- init_challengeGenKey
challengeLifetime <- init_challengeLifetime
challengeGenPeriod <- init_challengeGenPeriod
lastChallengeGenTimestamp <- init_lastChallengeGenTimestamp
```

###### COMMIT_KEY_UPDATE (new_commitKey)
```
n <- n + 1
commitKey[n] <- new_commitKey
```

###### AUTHENTICATE_CHALLENGE ()
```
present <- now()
timestamp <- present - [ (present - lastChallengeGenTimestamp) % challengeGenPeriod ]
challenge <- PRF(challengeGenKey, timestamp)
lastChallengeGenTimestamp <- timestamp
return (timestamp, challenge)
```

###### AUTHENTICATE_VERIFY (publicKey, tokenId, requestNonce, timestamp, signature)
```
if not (timestamp < now() < timestamp + challengeLifetime) then
    abort
challenge <- PRF(challengeGenKey, timestamp)
if not SIG_VERIFY(publicKey, tokenId || requestNonce || challenge, signature) then
    abort
```

###### COMMIT (ownerAddr, tokenId, requestNonce, timestamp, signature)
```
AUTHENTICATE_VERIFY(ownerAddr, tokenId, requestNonce, timestamp, signature)
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
