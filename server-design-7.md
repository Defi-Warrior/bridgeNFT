####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Support update commit key
- No database
- Support multiple servers
- Owner authentication using challenge generated from PRF
- Generate challenge periodically, with cache

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
challengeGenKey
challengeLifetime
challengeGenPeriod (< challengeLifetime)
lastChallengeGenTimestamp
lastChallenge
```

#### FUNCTION
###### SETUP (init_secretGenKey, init_indexEncKey, init_challengeGenKey, init_challengeLifetime, init_ challengeGenPeriod, init_lastChallengeGenTimestamp, init_lastChallenge)
```
n <- 0
secretGenKey[n] <- init_secretGenKey
indexEncKey <- init_indexEncKey
challengeGenKey <- init_challengeGenKey
challengeLifetime <- init_challengeLifetime
challengeGenPeriod <- init_challengeGenPeriod
lastChallengeGenTimestamp <- init_lastChallengeGenTimestamp
lastChallenge <- init_lastChallenge
```

###### SECRET_GEN_KEY_UPDATE (new_secretGenKey)
```
n <- n + 1
secretGenKey[n] <- new_secretGenKey
```

###### CHALLENGE ()
```
present <- now()
challengeGenTimestamp <- present - [ (present - lastChallengeGenTimestamp) % challengeGenPeriod ]
if challengeGenTimestamp = lastChallengeGenTimestamp then
    challenge <- lastChallenge
else then
    challenge <- PRF(challengeGenKey, challengeGenTimestamp)
    lastChallengeGenTimestamp <- challengeGenTimestamp
    lastChallenge <- challenge
return (challengeGenTimestamp, challenge)
```

###### VERIFY (bridgeRequest, challengeGenTimestamp, signature)
```
if not (challengeGenTimestamp < now() < challengeGenTimestamp + challengeLifetime) then
    abort
challenge <- PRF(challengeGenKey, challengeGenTimestamp)
if not SIG_VERIFY(tokenOwner, bridgeContext || requestNonce || tokenId || challenge, signature) then
    abort
```

###### COMMIT (bridgeRequest, challengeGenTimestamp, signature)
```
VERIFY(bridgeRequest, challengeGenTimestamp, signature)
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
