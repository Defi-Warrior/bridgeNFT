####  SUMMARY
- Deterministic secrets from multiple independent commit keys
- Support update commit key
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

bridgeContext := {
    fromChainId, fromTokenAddr, fromBridgeAddr,
    toChainId, toTokenAddr, toBridgeAddr
}
bridgeRequestId := { bridgeContext, tokenOwner, requestNonce }
bridgeRequest   := { bridgeRequestId, tokenId, challenge }
```

#### STORED GLOBAL VALUE
```
n
secretGenKey[]
indexEncKey
challengeMacKey
challengeLifetime
```

#### FUNCTION
###### SETUP (init_secretGenKey, init_indexEncKey, init_challengeMacKey, init_challengeLifetime)
```
n <- 0
secretGenKey[n] <- init_secretGenKey
indexEncKey <- init_indexEncKey
challengeMacKey <- init_challengeMacKey
challengeLifetime <- init_challengeLifetime
```

###### SECRET_GEN_KEY_UPDATE (new_secretGenKey)
```
n <- n + 1
secretGenKey[n] <- new_secretGenKey
```

###### CHALLENGE ()
```
challengeGenTimestamp <- now()
challenge <- random()
tag <- MAC_SIGN(challengeMacKey, challengeGenTimestamp || challenge)
return (challengeGenTimestamp, challenge, tag)
```

###### VERIFY (bridgeRequest, challengeGenTimestamp, tag, signature)
```
if not (challengeGenTimestamp < now() < challengeGenTimestamp + challengeLifetime) then
    abort
if not MAC_VERIFY(challengeMacKey, challengeGenTimestamp || challenge, tag) then
    abort
if not SIG_VERIFY(tokenOwner, bridgeContext || requestNonce || tokenId || challenge, signature) then
    abort
```

###### COMMIT (bridgeRequest, challengeGenTimestamp, tag, signature)
```
VERIFY(bridgeRequest, challengeGenTimestamp, tag, signature)
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
