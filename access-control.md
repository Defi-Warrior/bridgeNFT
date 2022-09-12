| Role                    | No. accounts | Appointable by              | Revocable by                | Action at revocation/update | Operate at            |
| ----------------------- | ------------ | --------------------------- | --------------------------- | --------------------------- | --------------------- |
| stopper                 | 1            | None, fixed from deployment | None, fixed from deployment | N/A                         | Admin                 |
| unpauser                |              |                             |                             |                             | Admin                 |
| pauser                  |              |                             |                             |                             | Admin                 |
| ----------------------- | ------------ | --------------------------- | --------------------------- | --------------------------- | --------------------- |
| appointingAuthority     | >=1          | None, self-update           | None, self-update           | pause                       | Admin                 |
| revokingAuthority       | >=1          | None, self-update           | None, self-update           | pause                       | Admin                 |
| ----------------------- | ------------ | --------------------------- | --------------------------- | --------------------------- | --------------------- |
| configManagingAuthority | >= 1         | appointingAuthority         | revokingAuthority           | None                        | Exchange              |
| processorAdder          | 1            | appointingAuthority         | revokingAuthority           | None                        | ProcessorProxy        |
| hasherAdder             | 1            | appointingAuthority         | revokingAuthority           | None                        | HasherRegistry        |
| sigVerifierAdder        | 1            | appointingAuthority         | revokingAuthority           | None                        | SigVerifierRegistry   |
| proofVerifierAdder      | 1            | appointingAuthority         | revokingAuthority           | None                        | ProofVerifierRegistry |
