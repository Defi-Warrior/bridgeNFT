//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IFromBridge.sol";
import "./events/IRevocableFromBridgeEvents.sol";

import "../../utils/Signature.sol";

interface IRevocableFromBridge is IFromBridge, IRevocableFromBridgeEvents {
    /**
     * @dev This function is called by administrative account(s) to switch the bridge
     * to using a new validator, therefore revoke the old validator.
     * @param newValidator The new validator.
     */
    function revokeValidator(address newValidator) external;

    /**
     * @dev This function is for the current validator to update a revoked validator's
     * signature (stored in contract storage) to his/her own signature.
     * This function will be needed in the case when the token has been processed at FromBridge
     * but the validator who processed that request has been revoked and the owner has not yet
     * acquire the new one at ToBridge.
     * @param messageContainer The signed message. It needs to be sent back because the message
     * or the data to craft the message was not saved in the contract storage at commit transaction.
     * Because all revocation-related functions would be called far less frequently than the
     * "commit" function, not saving the message in storage is more gas-effective.
     * The message MUST be re-verify against the old signature to ensure it is the same one
     * when committing.
     * @param requestNonce The request's nonce, alongside the token owner's address
     * (included in "messageContainer"), are needed to uniquely identifies a request.
     * @param newValidatorSignature The new signature to update to, signed by the current validator.
     */
    function updateValidatorSignature(
        ValidatorSignature.MessageContainer memory messageContainer,
        uint256 requestNonce,
        bytes calldata newValidatorSignature
    ) external;
}
