//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IClaimToBridge.sol";
import "./AbstractToBridge.sol";

/**
 * @title AbstractClaimToBridge
 * @dev The version of ToBridge that has claim functionality.
 */
abstract contract AbstractClaimToBridge is IClaimToBridge, AbstractToBridge {
    using Address for address;

    struct ClaimDetail {
        address claimer;
        bytes   tokenUri;
        uint256 timestamp;
        uint256 waitingDurationToAcquireByClaim;
        uint256 escrow;
        bool    denied;
    }

    /**
     * @dev (Blockchain) Address of the denier that has right to deny claims.
     */
    address internal _denier;

    /**
     * @dev The duration the token owner needs
     * to wait in order to acquire by claim, starting from claim's timestamp
     * determined by ToBridge. This is to give the validator time to deny claim.
     */
    uint256 internal _globalWaitingDurationToAcquireByClaim;

    /**
     * @dev Users must send an escrow amount when claimming.
     * So this variable specifies the minimum value of that amount.
     */
    uint256 internal _minimumEscrow;

    /**
     * Mapping from validator's commitment to claim.
     *
     * Even if there were multiple tokens with same token ID requested to be bridged,
     * the commitment would be different each time (with high probability). Therefore commitment
     * could be used as an identity for every requests, acquirements and claims.
     */
    mapping(bytes32 => ClaimDetail) internal _claims;

    /* ********************************************************************************************** */

    modifier onlyDenier(string memory errorMessage) {
        require(msg.sender == _denier, errorMessage);
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(
        address toToken,
        address validator,
        uint256 globalWaitingDurationForOldTokenToBeProcessed,
        address denier,
        uint256 globalWaitingDurationToAcquireByClaim,
        uint256 minimumEscrow
    ) AbstractToBridge(toToken, validator, globalWaitingDurationForOldTokenToBeProcessed) {
        _checkDenierRequirements(denier);
        _checkGlobalWaitingDurationToAcquireByClaimRequirements(globalWaitingDurationToAcquireByClaim);
        _checkMinimumEscrowRequirements(minimumEscrow);

        _denier = denier;
        _globalWaitingDurationToAcquireByClaim = globalWaitingDurationToAcquireByClaim;
        _minimumEscrow = minimumEscrow;
    }

    /**
     * @dev Check all "denier" requirements.
     *
     * Currently the checks are:
     * - Denier is an EOA. Unfortunately, this cannot be done in this version of Solidity
     * and the check only exclude the case denier is a contract.
     */
    function _checkDenierRequirements(address denier) internal view virtual {
        // "isContract" function returns false does NOT mean that address is an EOA.
        // See OpenZeppelin "Address" library for more information.
        require(!denier.isContract(), "AbstractFromBridge.constructor: denier must not be a contract");
    }

    /**
     * @dev Check all "globalWaitingDurationToAcquireByClaim" requirements.
     *
     * Currently there is no check. Child contracts MAY override this function to
     * add check(s) if needed.
     */
    function _checkGlobalWaitingDurationToAcquireByClaimRequirements(
        uint256 globalWaitingDurationToAcquireByClaim
    ) internal view virtual {}

    /**
     * @dev Check all "minimumEscrow" requirements.
     *
     * Currently there is no check. Child contracts MAY override this function to
     * add check(s) if needed.
     */
    function _checkMinimumEscrowRequirements(
        uint256 minimumEscrow
    ) internal view virtual {}

    /**
     * @dev See IClaimToBridge.
     * "_denier" getter.
     */
    function getDenier() external view override returns(address) {
        return _denier;
    }

    /**
     * @dev "_denier" setter.
     */
    function setDenier(address newDenier) external
            onlyAdmin("setDenier: Only admin can change denier") {
        _checkDenierRequirements(newDenier);
        _denier = newDenier;
    }

    /**
     * @dev See IClaimToBridge.
     * "_globalWaitingDurationToAcquireByClaim" getter.
     */
    function getGlobalWaitingDurationToAcquireByClaim() external view override returns(uint256) {
        return _globalWaitingDurationToAcquireByClaim;
    }

    /**
     * @dev "_globalWaitingDurationToAcquireByClaim" setter.
     */
    function setGlobalWaitingDurationToAcquireByClaim(uint256 newGlobalWaitingDurationToAcquireByClaim) external
            onlyAdmin("setGlobalWaitingDurationToAcquireByClaim: Only admin can change globalWaitingDurationToAcquireByClaim") {
        _checkGlobalWaitingDurationToAcquireByClaimRequirements(newGlobalWaitingDurationToAcquireByClaim);
        _globalWaitingDurationToAcquireByClaim = newGlobalWaitingDurationToAcquireByClaim;
    }

    /**
     * @dev See IClaimToBridge.
     * "_minimumEscrow" getter.
     */
    function getMinimumEscrow() external view override returns(uint256) {
        return _minimumEscrow;
    }

    /**
     * @dev "_minimumEscrow" setter.
     */
    function setMinimumEscrow(uint256 newMinimumEscrow) external
            onlyAdmin("setMinimumEscrow: Only admin can change minimumEscrow") {
        _checkMinimumEscrowRequirements(newMinimumEscrow);
        _minimumEscrow = newMinimumEscrow;
    }

    /* ********************************************************************************************** */

    /**
     * @dev See IClaimToBridge.
     */
    function claim(
        Origin calldata origin,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) public virtual override payable nonReentrant {
        Destination memory destination = Destination(block.chainid, getToToken(), address(this));

        // Calculate the escrow of this claim.
        uint256 claimEscrow = _calculateClaimEscrow(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            commitment,
            requestTimestamp,
            validatorSignature);

        // Check all requirements to claim.
        _checkClaimRequiments(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            commitment,
            requestTimestamp,
            validatorSignature,
            claimEscrow);

        // Update all state variables needed.
        _updateStateWhenClaim(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            commitment,
            requestTimestamp,
            validatorSignature,
            claimEscrow);

        // Emit all events needed.
        _emitEventsWhenClaim(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            commitment,
            requestTimestamp,
            validatorSignature,
            claimEscrow);
    }

    /**
     * @dev Check all requirements to claim token. If an child contract has more
     * requirements, when overriding it SHOULD first call super._checkClaimRequiments(...)
     * then add its own requirements.
     * Parameters are that of "claim" function plus "destination" and "claimEscrow".
     *
     * Currently the checks are:
     * - Validator's signature.
     * - The claim does not exist (i.e. the "claim" function is called the first time).
     * - The new token has not yet been acquired.
     * - The claim has not yet been denied by the validator.
     * - The message sender is the token owner.
     * - The escrow in claim is at least the minimum escrow for the claim.
     * - The commit transaction at FromBridge is finalized.
     */
    function _checkClaimRequiments(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory validatorSignature,
        uint256 claimEscrow
    ) internal view virtual {
        // Verify validator's signature.
        require(
            ValidatorSignature.verify(
                _validator,
                ValidatorSignature.MessageContainer(
                    origin.fromChainId, origin.fromToken, origin.fromBridge,
                    destination.toChainId, destination.toToken, destination.toBridge,
                    tokenOwner,
                    oldTokenInfo.tokenId, oldTokenInfo.tokenUri,
                    commitment, requestTimestamp),
                validatorSignature),
            "Claim: Invalid validator signature");

        // The claim must not exist.
        require(!_existsClaim(commitment), "Claim: Claim already exists");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "Claim: Token has been acquired");

        // The claim must not have been denied by the validator.
        require(!_isDenied(commitment), "Claim: Token has been denied by the validator");

        // By policy, token owners must acquire by themselves.
        require(msg.sender == tokenOwner, "Claim: Token can only be acquired by its owner");

        // Revert if sended escrow is not enough.
        require(claimEscrow >= _calculateMinimumEscrowForClaim(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            commitment,
            requestTimestamp,
            validatorSignature
        ), "Claim: Escrow is not enough");

        // Revert if user did not wait enough time.
        require(block.timestamp > requestTimestamp + _globalWaitingDurationForOldTokenToBeProcessed,
            "Claim: Elapsed time from request is not enough");
    }

    /**
     * @dev Check if the claim identified by the specified commitment exists.
     * @param commitment The validator's commitment. It uniquely identifies every claim.
     * @return true if the claim exists.
     */
    function _existsClaim(bytes32 commitment) internal view returns(bool) {
        return _claims[commitment].timestamp != 0;
    }

    /**
     * @dev Check if the claim identified by the specified commitment has been denied
     * by the validator.
     * @param commitment The validator's commitment. It uniquely identifies every claim.
     * @return true if the claim has already been denied.
     */
    function _isDenied(bytes32 commitment) internal view returns(bool) {
        return _claims[commitment].denied;
    }
    
    /**
     * @dev Calculate the escrow of the input claim.
     * Child contracts MAY override this function to change the escrow mechanism (e.g. using
     * ERC20 token for escrow). The chain's native currency is used for escrow by default.
     * Parameters are that of "claim" function plus "destination". All values are put in parameter
     * to cover all possible calculations based on the claim's data.
     * @return The escrow of the input claim.
     */
    function _calculateClaimEscrow(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal view virtual returns(uint256) {
        return msg.value;
    }

    /**
     * @dev Calculate the minimum escrow for the input claim.
     * Child contracts MAY override this function to change the escrow mechanism.
     * The "_minimumEscrow" state variable is returned by default.
     * Parameters are the same as "_calculateClaimEscrow" function. All values are put in parameter
     * to cover all possible calculations based on the claim's data.
     * @return The minimum escrow of the input claim.
     */
    function _calculateMinimumEscrowForClaim(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal view virtual returns(uint256) {
        return _minimumEscrow;
    }

    /**
     * @dev Save or update all the state variables needed.
     * Child contracts MAY override if they had other state variables needing to be saved or updated.
     * In that case, super._updateStateWhenClaim() MUST be called to keep the parent contracts' state consistent.
     * Parameters are the same as "_checkClaimRequiments" function. All values are put in parameter
     * to cover all possible cases.
     *
     * When overriding this function, DO NOT make external call to keep the function's meaning.
     * Overriding functions MUST only carry out modifications to the contract's storage.
     */
    function _updateStateWhenClaim(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory validatorSignature,
        uint256 claimEscrow
    ) internal virtual {
        // Save claim.
        _saveClaim(
            commitment,
            tokenOwner,
            oldTokenInfo.tokenUri,
            block.timestamp,
            _globalWaitingDurationToAcquireByClaim,
            claimEscrow,
            false);
    }

    /**
     * @dev Save claim to contract's storage.
     */
    function _saveClaim(
        bytes32 commitment,
        address claimer,
        bytes memory tokenUri,
        uint256 timestamp,
        uint256 waitingDurationToAcquireByClaim,
        uint256 claimEscrow,
        bool denied
    ) internal {
        _claims[commitment] = ClaimDetail(
            claimer,
            tokenUri,
            timestamp,
            waitingDurationToAcquireByClaim,
            claimEscrow,
            denied);
    }

    /**
     * @dev Emit all the events needed. Child contracts MAY override to emit the events they want.
     * However, super._emitEventsWhenClaim() SHOULD be called to keep emitting the events of parent contracts.
     * Parameters are the same as "_updateStateWhenClaim" function. All values are put in parameter
     * to cover all possible events.
     *
     * When overriding this function, DO NOT make external call to keep the function's meaning.
     * Overriding functions MUST only carry out modifications to the contract's storage.
     */
    function _emitEventsWhenClaim(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment,
        uint256 requestTimestamp,
        bytes memory validatorSignature,
        uint256 claimEscrow
    ) internal virtual {
        emit Claim(
            origin.fromChainId,
            origin.fromToken,
            origin.fromBridge,
            commitment,
            block.timestamp);
    }

    /* ********************************************************************************************** */

    /**
     * @dev See IClaimToBridge.
     */
    function acquireByClaim(bytes32 commitment) public virtual override nonReentrant {
        // Retrieve claim.
        ClaimDetail storage claimDetail = _claims[commitment];

        // Check all requirements to acquire by claim.
        _checkAcquireByClaimRequiments(commitment, claimDetail);

        // Mint a new token corresponding to the old one.
        uint256 newTokenId = _mint(claimDetail.claimer, claimDetail.tokenUri);

        // Return escrow back to claimer.
        _sendEscrow(claimDetail.claimer, claimDetail.escrow);

        // Update all state variables needed.
        _updateStateWhenAcquireByClaim(commitment, claimDetail, newTokenId);

        // Emit all events needed.
        _emitEventsWhenAcquireByClaim(commitment, claimDetail, newTokenId);
    }

    /**
     * @dev Check all requirements to acquire token by claim. If an child contract has more
     * requirements, when overriding it SHOULD first call super._checkAcquireByClaimRequiments(...)
     * then add its own requirements.
     * @param commitment The validator's commitment.
     * @param claimDetail The detail of the claim retrieved using the given commitment.
     *
     * Currently the checks are:
     * - The claim exists (i.e. the "claim" function was called before "acquireByClaim" function).
     * - The new token has not yet been acquired.
     * - The claim has not yet been denied by the validator.
     * - The message sender is the claimer (token owner).
     * - All time-related requirements are delegated to "_checkAcquireByClaimTimeRequiments" function.
     */
    function _checkAcquireByClaimRequiments(bytes32 commitment, ClaimDetail storage claimDetail) internal view virtual {
        // The claim must exist.
        require(_existsClaim(commitment), "AcquireByClaim: Claim does not exist");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "AcquireByClaim: Token has been acquired");

        // The claim must not have been denied by the validator.
        require(!_isDenied(commitment), "AcquireByClaim: Token has been denied by the validator");

        // By policy, token owners must acquire by themselves.
        // The claimer is token owner (verified when claimming).
        require(msg.sender == claimDetail.claimer, "AcquireByClaim: Token can only be acquired by its owner");

        // Check all time-related requirements.
        _checkAcquireByClaimTimeRequiments(claimDetail);
    }

    /**
     * @dev All time-related requirements are separated from "_checkAcquireByClaimRequiments"
     * function into this function for the purpose of functionality extension (e.g. pausability).
     * If a contract inherits this contract and adds some time-related logic, it SHOULD override
     * this function.
     *
     * Currently the checks are:
     * - The time elapsed after claimming is larger than "waitingDurationToAcquireByClaim",
     * which is determined when claimming.
     */
    function _checkAcquireByClaimTimeRequiments(ClaimDetail storage claimDetail) internal view virtual {
        // Revert if user did not wait enough time.
        require(block.timestamp > claimDetail.timestamp + claimDetail.waitingDurationToAcquireByClaim,
            "AcquireByClaim: Elapsed time from claim is not enough");
    }

    /**
     * @dev Save or update all the state variables needed.
     * Child contracts MAY override if they had other state variables needing to be saved or updated.
     * In that case, super._updateStateWhenAcquireByClaim() MUST be called to keep the parent contracts' state consistent.
     * Parameters are that of "_checkAcquireByClaimRequiments" function plus "newTokenId". All values are put in parameter
     * to cover all possible cases.
     *
     * When overriding this function, DO NOT make external call to keep the function's meaning.
     * Overriding functions MUST only carry out modifications to the contract's storage.
     */
    function _updateStateWhenAcquireByClaim(
        bytes32 commitment,
        ClaimDetail storage claimDetail,
        uint256 newTokenId
    ) internal virtual {
        // Mark request as acquired.
        _markRequestAcquired(commitment);
    }

    /**
     * @dev Emit all the events needed. Child contracts MAY override to emit the events they want.
     * However, super._emitEventsWhenAcquireByClaim() SHOULD be called to keep emitting the events of parent contracts.
     * Parameters are the same as "_updateStateWhenAcquireByClaim" function. All values are put in parameter
     * to cover all possible events.
     *
     * When overriding this function, DO NOT make external call to keep the function's meaning.
     * Overriding functions MUST only carry out modifications to the contract's storage.
     */
    function _emitEventsWhenAcquireByClaim(
        bytes32 commitment,
        ClaimDetail storage claimDetail,
        uint256 newTokenId
    ) internal virtual {
        emit AcquireByClaim(
            claimDetail.claimer,
            newTokenId,
            commitment,
            block.timestamp);
    }

    /* ********************************************************************************************** */

    /**
     * @dev See IClaimToBridge.
     */
    function deny(bytes32 commitment)
    public virtual override onlyDenier("Deny: Only denier is allowed to deny") {
        // Retrieve claim.
        ClaimDetail storage claimDetail = _claims[commitment];

        // Check all requirements to acquire by claim.
        _checkDenyRequiments(commitment, claimDetail);

        // Modify contract's state to reflect the denial.
        _deny(commitment);

        // Send escrow to denier.
        _sendEscrow(_denier, claimDetail.escrow);

        // Emit all events needed.
        _emitEventsWhenDeny(commitment, claimDetail);
        
    }

    /**
     * @dev Check all requirements to deny claim. If an child contract has more
     * requirements, when overriding it SHOULD first call super._checkDenyRequiments(...)
     * then add its own requirements.
     * @param commitment The validator's commitment.
     * @param claimDetail The detail of the claim retrieved using the given commitment.
     * This parameter is not used for now but still in parameters to cover the case
     * there is any child contract overrides this function and uses the claim's data.
     *
     * Currently the checks are:
     * - The claim exists (i.e. the "claim" function was called before "acquireByClaim" function).
     * - The new token has not yet been acquired.
     * - The claim has not yet been denied by the validator.
     */
    function _checkDenyRequiments(bytes32 commitment, ClaimDetail storage claimDetail) internal view virtual {
        // The claim must exist.
        require(_existsClaim(commitment), "Deny: Claim does not exist");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "Deny: Token has been acquired");

        // The claim must not have been denied by the validator.
        require(!_isDenied(commitment), "Deny: Token has been denied by the validator");
    }

    /**
     * @dev This function is the core of denial process. Child contract MAY override
     * this function if it adds more logic.
     * @param commitment The validator's commitment. It uniquely identifies every claim.
     */
    function _deny(bytes32 commitment) internal virtual {
        _claims[commitment].denied = true;
    }

    /**
     * @dev Send escrow out, either back to the claimer (when acquired by claim)
     * or to the denier (when denied).
     * @param to Address to send escrow to.
     * @param escrow Amount of escrow.
     */
    function _sendEscrow(address to, uint256 escrow) internal virtual {
        payable(to).transfer(escrow);
    }

    /**
     * @dev Emit all the events needed. Child contracts MAY override to emit the events they want.
     * However, super._emitEventsWhenDeny() SHOULD be called to keep emitting the events of parent contracts.
     * Parameters are the same as "_checkDenyRequiments" function. All values are put in parameter
     * to cover all possible events.
     *
     * When overriding this function, DO NOT make external call to keep the function's meaning.
     * Overriding functions MUST only carry out modifications to the contract's storage.
     */
    function _emitEventsWhenDeny(bytes32 commitment, ClaimDetail storage claimDetail) internal virtual {
        emit Deny(commitment, block.timestamp);
    }
}
