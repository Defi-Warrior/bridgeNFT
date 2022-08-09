//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IRevocableToBridge.sol";
import "./AbstractToBridge.sol";

import "./interfaces/IValidatorRevocationAnnouncementReceiver.sol";

/**
 * @title AbstractRevocableToBridge
 * @dev The version of ToBridge that supports revoking validator then switching to a new one.
 */
abstract contract AbstractRevocableToBridge is IRevocableToBridge, AbstractToBridge {
    uint256 private constant _MAX_ANNOUNCEMENT_GAS = 10000;

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
        _announceRevocationToAll(revokedValidator, newValidator, msg.sender);

        // Emit event.
        emit Revoke(revokedValidator, newValidator, msg.sender, block.timestamp);
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
     * @dev See _announceRevocationToAll.
     * Announce the revocation to one contract.
     *
     * This function do not propagate the exception thrown by the called contract to not
     * interfere with the revocation, and also, to the announcement to other contracts.
     * Therefore, low-level call is used to swallow exception.
     *
     * The gas is specified to prevent the receiver from consuming too much gas and
     * affect the revocation transaction. For this reason, the receiver might fail to
     * update its state to reflect the revocation and might lead to security issues.
     *
     */
    function _announceRevocationTo(
        address receiver,
        address revokedValidator,
        address newValidator,
        address revoker
    ) internal {
        require(gasleft() >= _MAX_ANNOUNCEMENT_GAS);

        receiver.call{ gas: _MAX_ANNOUNCEMENT_GAS }( abi.encodeWithSelector(
            IValidatorRevocationAnnouncementReceiver.receiveAnnouncement.selector,
            revokedValidator,
            newValidator,
            revoker) );
    }
}
