### Comparison between bridge versions

| Version | 1 | 2 | 3 |
| ------------------------------------------------------------ | --------- | --------- | ------------------ |
| Server's number of transactions (in 1 smooth process) | 1 (4) | 1 (3) | 2 (3, 5a) |
| User's number of transactions (in 1 smooth process) | 2 (2, 6a) | 1 (5a) | 1 (7a) |
| Mechanisms to prevent cheats | Timestamp + token lock | Timestamp | Escrow |
| Need user to trust server (because of disallowing mechanism) | Yes | Yes | No |
| Escrow of server | No | No | Yes (ETH or ERC20) |
| Burn old token immediately (so no need to lock) | No | Yes | Yes |
| FromBridge | Stateful | Stateless | Stateful |
| ToBridge | Stateful | Stateful | Stateless |
| Total time user have to wait for 1 smooth process | A + B | A + B | A |
| Total time user have to wait to claim back token/escrow (when abnormalities happen) | A + B | - | C |
| Potential attacks on server | Server is isolated (DoS) from **BOTH** FromBridge and ToBridge for duration **A + B** | Server is isolated (DoS) from **BOTH** FromBridge and ToBridge for duration **A + B** | Server is isolated (DoS) from FromBridge for duration **C** |
| Potential attacks on user | Server disallows acquirement even when confirm transaction is finalized | Server disallows acquirement even when confirm transaction is finalized |  |

###### Time explanations
- A: Time needed for 1 transaction to be finalized (included in a block that is 6-block far from the newest block). Typically, A may be 10 minutes.
- B: Time room for server to act in case abnormalities happen. B must be >= A. Typically, B may also be 10 minutes.
- C: Because when DoS attacking the server, the attack goal in version 3 (only isolating with FromBridge) is somewhat easier than that in version 1 and 2 (isolating with both bridges). The time constraint C must be >> A + B. Typically, C may be 3 days.