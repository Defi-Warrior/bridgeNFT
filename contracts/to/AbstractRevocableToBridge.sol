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
    /**
     * @dev Max gas for receiver contract can consume to update state.
     */
    uint256 private constant _MAX_ANNOUNCEMENT_GAS = 30000;

    /**
     * @dev See IRevocableToBridge.
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
}
