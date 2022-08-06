//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IRevocableFromBridge.sol";
import "./AbstractFromBridge.sol";

/**
 * @title AbstractRevocableFromBridge
 * @dev The version of FromBridge that supports revoking validator then switching to a new one.
 */
abstract contract AbstractRevocableFromBridge is IRevocableFromBridge, AbstractFromBridge {
    /**
     * @dev See IRevocableFromBridge.
     * Child contracts MAY override this function if they want further fine-grained control
     * over who has the right to revoke.
     */
    function revokeValidator(address newValidator) external virtual override
            onlyAdmin("revokeValidator: Only admin can revoke validator") {
        // Emit event.
        emit Revoke(_validator, newValidator, msg.sender);
        // Update validator.
        _validator = newValidator;
    }

    /**
     * @dev See AbstractFromBridge.
     * Override "AbstractFromBridge.getValidatorSignature" function to add check if the validator
     * who processed the request matches the current one.
     */
    function getValidatorSignature(uint256 requestNonce)
            public view virtual override(IFromBridge, AbstractFromBridge) returns(bytes memory) {
        // Retrieve might-be-revoked validator and signature.
        ValidatorAndSignature storage validatorAndSignature
            = _validatorAndSignatures[msg.sender][requestNonce];

        // Check that validator versus the current one.
        require(validatorAndSignature.validator == _validator,
            "getValidatorSignature: The validator who signed this signature has been revoked");

        return validatorAndSignature.signature;
    }

    /**
     * @dev See IRevocableFromBridge.
     */
    function updateValidatorSignature(
        ValidatorSignature.MessageContainer memory messageContainer,
        uint256 requestNonce,
        bytes memory newValidatorSignature
    ) external override onlyValidator("updateValidatorSignature: Only the current validator can update signature") {
        // Retrieve old validator and signature.
        ValidatorAndSignature storage oldValAndSig
            = _validatorAndSignatures[messageContainer.tokenOwner][requestNonce];

        // Verify old validator's signature to ensure the input message is the message
        // that was signed by the old validator in the past.
        require(
            ValidatorSignature.verify(
                oldValAndSig.validator,
                messageContainer,
                oldValAndSig.signature),
            "updateValidatorSignature: Invalid message");

        // Verify new validator's signature.
        require(
            ValidatorSignature.verify(
                _validator,
                messageContainer,
                newValidatorSignature),
            "updateValidatorSignature: Invalid new validator signature");

        // Emit event.
        emit UpdateValidatorSignature(
            messageContainer.tokenOwner,
            requestNonce,
            oldValAndSig.validator,
            oldValAndSig.signature,
            _validator,
            newValidatorSignature);

        // Update state variable.
        _validatorAndSignatures[messageContainer.tokenOwner][requestNonce] =
            ValidatorAndSignature(_validator, newValidatorSignature);
    }
}
