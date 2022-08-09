//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IToBridge.sol";
import "./events/IRevocableToBridgeEvents.sol";

interface IRevocableToBridge is IToBridge, IRevocableToBridgeEvents {
    /**
     * @dev This function is called by administrative account(s) to switch the bridge
     * to using a new validator, therefore revoke the old validator.
     * @param newValidator The new validator.
     */
    function revokeValidator(address newValidator) external;
}
