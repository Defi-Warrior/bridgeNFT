//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../AbstractClaimToBridge.sol";
import "../../AbstractRevocableToBridge.sol";

import "../../interfaces/IToTokenMinter.sol";
import "./interfaces/INFTManager.sol";
import "../../../utils/defi-warrior/WarriorEncoding.sol";

/**
 * @title DefiWarriorToBridge
 * @dev ToBridge specialized for Defi Warrior NFT, supporting claim functionality
 * and validator revocation.
 * See respective parent contracts for further explanations.
 */
contract DefiWarriorToBridge is AbstractClaimToBridge, AbstractRevocableToBridge {
    using Address for address;

    address private immutable _nftManager;

    /**
     * @dev Constructor.
     */
    constructor(
        address toToken,
        address validator,
        uint256 globalWaitingDurationForOldTokenToBeProcessed,
        address denier,
        uint256 globalWaitingDurationToAcquireByClaim,
        uint256 minimumEscrow,
        address nftManager)
            AbstractToBridge(toToken, validator, globalWaitingDurationForOldTokenToBeProcessed)
            AbstractClaimToBridge(denier, globalWaitingDurationToAcquireByClaim, minimumEscrow) {
        
        _checkNftManagerRequirements(nftManager);

        _nftManager = nftManager;
    }

    /**
     * @dev "_nftManager" getter.
     */
    function getNftManager() public view returns(address) {
        return _nftManager;
    }

    /**
     * @dev Check all "nftManager" requirements.
     *
     * Currently the checks are:
     * - "nftManager" is a contract.
     */
    function _checkNftManagerRequirements(address nftManager) internal view {
        require(nftManager.isContract(), "DefiWarriorToBridge.constructor: NFTManager must be a contract");
    }

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractToBridge.
     */
    function isCurrentlyMintable() public view override(IToBridge, AbstractToBridge) returns(bool) {
        return IToTokenMinter(_nftManager).isCurrentlyMintable();
    }

    /**
     * @dev See AbstractToBridge.
     */
    function _mint(address to, bytes memory tokenUri) internal override returns(uint256) {
        uint32[30] memory warriorAttributes;
        uint32[20][6] memory bodypartAttributes;
        
        (warriorAttributes, bodypartAttributes) = WarriorEncoding.decode(tokenUri);

        uint256 newTokenId = INFTManager(_nftManager).mint(to, warriorAttributes, bodypartAttributes);

        return newTokenId;
    }

    /* ********************************************************************************************** */

    /**
     * @dev See AbstractRevocableToBridge.
     */
    function _announceRevocationToAll(address revokedValidator, address newValidator, address revoker) internal override {
        _announceRevocationTo(_nftManager, revokedValidator, newValidator, revoker);
    }
}
