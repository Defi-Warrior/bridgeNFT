//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IRevocableFromBridge.sol";
import "./AbstractFromBridge.sol";

import "./interfaces/IValidatorRevocationAnnouncementReceiver.sol";

/**
 * @title AbstractRevocableFromBridge
 * @dev The version of FromBridge that supports revoking validator then switching to a new one.
 */
abstract contract AbstractRevocableFromBridge is IRevocableFromBridge, AbstractFromBridge {
    /**
     * @dev Max gas for receiver contract can consume to update state.
     */
    uint256 private constant _MAX_ANNOUNCEMENT_GAS = 30000;

    /**
     * @dev See IRevocableFromBridge.
     * Child contracts MAY override this function if they want further fine-grained control
     * over who has the right to revoke.
     */
    function revokeValidator(address newValidator) external virtual override
            onlyAdmin("revokeValidator: Only admin can revoke validator") {
        // Check all validator requirements.
        _checkValidatorRequirements(newValidator);

        // Announe revocation to other contracts.
        _announceRevocationToAll(_validator, newValidator, msg.sender);

        // Emit event.
        emit Revoke(_validator, newValidator, msg.sender, block.timestamp);

        // Update validator.
        _validator = newValidator;
    }

    /**
     * @dev This function is used to announce the revocation to other contracts so that they could
     * take proper subsequent actions if needed. Child contracts MAY override to add the
     * announcement(s) they need.
     *
     * The receivers (i.e. announcement receiving contracts) MUST implement the
     * "IValidatorRevocationAnnouncementReceiver" interface.
     *
     * When overriding, the "_announceRevocationTo" function MUST be used to announce to each receiver.
     * Child contracts MAY optionally implement observer pattern to get more dynamic control over
     * the receiver list.
     */
    function _announceRevocationToAll(
        address revokedValidator,
        address newValidator,
        address revoker
    ) internal virtual {}

    /**
     * @dev See "_announceRevocationToAll" function.
     * Announce the revocation to one contract.
     *
     * This function do not propagate the exception thrown by the called contract to not
     * interfere with the revocation, and also, to the announcement to other contracts.
     * Therefore, low-level call is used to swallow exception.
     *
     * The gas is specified to prevent the receiver from consuming too much gas and
     * affect the revocation transaction. For this reason, the receiver might fail to
     * update its state to reflect the revocation and might lead to security issues.
     * This is a dilemma between revocation success and announcement success. We chose
     * to prioritized the revocation.
     */
    function _announceRevocationTo(
        address receiver,
        address revokedValidator,
        address newValidator,
        address revoker
    ) internal {
        require(gasleft() >= _MAX_ANNOUNCEMENT_GAS, "revokeValidator: Not enough gas to announce to all");

        receiver.call{ gas: _MAX_ANNOUNCEMENT_GAS }( abi.encodeWithSelector(
            IValidatorRevocationAnnouncementReceiver.receiveAnnouncement.selector,
            revokedValidator,
            newValidator,
            revoker) );
    }

    /* ********************************************************************************************** */

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
