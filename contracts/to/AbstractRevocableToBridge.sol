//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IRevocableToBridge.sol";
import "./AbstractToBridge.sol";

/**
 * @title AbstractRevocableToBridge
 * @dev The version of ToBridge that supports revoking validator then switching to a new one.
 */
abstract contract AbstractRevocableToBridge is IRevocableToBridge, AbstractToBridge {
    /**
     * @dev See IRevocableToBridge.
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
}
