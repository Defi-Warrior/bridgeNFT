//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Signature {
    function verifySignature(
        address signer,
        bytes memory message,
        bytes memory signature
    ) internal view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer, ECDSA.toEthSignedMessageHash(message), signature);
    }
}