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
        // Check all validator requirements.
        _checkValidatorRequirements(newValidator);

        address revokedValidator = _validator;

        // Update validator.
        _validator = newValidator;

        // Announe revocation to other contracts.
        _announceRevocation(revokedValidator, newValidator, msg.sender);

        // Emit event.
        emit Revoke(revokedValidator, newValidator, msg.sender, block.timestamp);
    }

    /**
     * @dev This function is used to announce the revocation to other contracts so that they could
     * take proper subsequent actions if needed. Child contracts MAY override to add the
     * announcement(s) they need.
     *
     * This function SHOULD NOT propagate the exceptions thrown by the called contracts to not
     * interfere with the revocation. Also, an announcement to a contract SHOULD not interfere with
     * announcements to other contracts as well. Therefore, there SHOULD be a try-catch block
     * that swallows exception for each external call. Or alternatively, use the low-level
     * "address.call".
     */
    function _announceRevocation(address revokedValidator, address newValidator, address revoker) internal virtual {}

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
