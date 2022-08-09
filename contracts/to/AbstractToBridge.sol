//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IToBridge.sol";
import "../utils/Commitment.sol";
import "../utils/Signature.sol";

/**
 * @title AbstractToBridge
 * @dev This contract carries out the second part of the process of bridging (converting)
 * user's tokens from a ERC721 NFT to "another" ERC721 NFT.
 *
 * Both NFTs may be different contracts on the same chain, or may be on different chains.
 * In fact, they could be the same NFT. There is no restriction on the origin and
 * destination NFT.
 *
 * The second part is essentially minting new NFTs corresponding to the old ones for users.
 */
abstract contract AbstractToBridge is IToBridge, Ownable, ReentrancyGuard {
    using Address for address;

    /**
     * Address of the ERC721 contract that tokens will be convert to.
     */
    address private immutable _toToken;

    /**
     * (Blockchain) Address of the validator that confirms request on the other chain
     * and provides user signature to obtain the new token on this chain.
     */
    address internal _validator;

    /**
     * The duration the token owner needs to wait in order to acquire, starting from
     * request's timestamp determined by the validator. This is to ensure that
     * the "commit" transaction on the old chain is finalized.
     */
    uint256 internal _globalWaitingDurationForOldTokenToBeProcessed;

    /**
     * Mapping from validator's commitment to a boolean value determining if the
     * new token has been acquired or not. The boolean value will only be set to
     * true if a transaction call to "acquire" function succeeds.
     *
     * The commitment is unique (with high probability) for every request, therefore
     * could be used as an identity for requests.
     */
    mapping(bytes32 => bool) internal _acquiredRequests;

    /* ********************************************************************************************** */

    modifier onlyAdmin(string memory errorMessage) {
        require(msg.sender == owner(), errorMessage);
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(
        address toToken,
        address validator,
        uint256 globalWaitingDurationForOldTokenToBeProcessed
    ) {
        _checkToTokenRequirements(toToken);
        _checkValidatorRequirements(validator);
        _checkGlobalWaitingDurationForOldTokenToBeProcessedRequirements(globalWaitingDurationForOldTokenToBeProcessed);

        _toToken = toToken;
        _validator = validator;
        _globalWaitingDurationForOldTokenToBeProcessed = globalWaitingDurationForOldTokenToBeProcessed;
    }

    /**
     * @dev Check all "toToken" requirements.
     *
     * Currently the checks are:
     * - "toToken" is a contract.
     */
    function _checkToTokenRequirements(address toToken) internal view virtual {
        require(toToken.isContract(), "AbstractStaticToBridge.constructor: ToToken must be a contract");
    }

    /**
     * @dev Check all "validator" requirements.
     *
     * Currently the checks are:
     * - Validator is an EOA. Unfortunately, this cannot be done in this version of Solidity
     * and the check only exclude the case validator is a contract.
     */
    function _checkValidatorRequirements(address validator) internal view virtual {
        // "isContract" function returns false does NOT mean that address is an EOA.
        // See OpenZeppelin "Address" library for more information.
        require(!validator.isContract(), "AbstractFromBridge.constructor: validator must not be a contract");
    }

    /**
     * @dev Check all "globalWaitingDurationForOldTokenToBeProcessed" requirements.
     *
     * Currently there is no check. Child contracts MAY override this function to
     * add check(s) if needed.
     */
    function _checkGlobalWaitingDurationForOldTokenToBeProcessedRequirements(
        uint256 globalWaitingDurationForOldTokenToBeProcessed
    ) internal view virtual {}

    /**
     * @dev See IToBridge.
     * "_toToken" getter.
     */
    function getToToken() public view override returns(address) {
        return _toToken;
    }

    /**
     * @dev See IToBridge.
     * "_validator" getter.
     */
    function getValidator() external view override returns(address) {
        return _validator;
    }

    /**
     * @dev See IToBridge.
     * "_globalWaitingDurationForOldTokenToBeProcessed" getter.
     */
    function getGlobalWaitingDurationForOldTokenToBeProcessed() external view override returns(uint256) {
        return _globalWaitingDurationForOldTokenToBeProcessed;
    }

    /**
     * @dev "_globalWaitingDurationForOldTokenToBeProcessed" setter.
     */
    function setGlobalWaitingDurationForOldTokenToBeProcessed(uint256 newGlobalWaitingDurationForOldTokenToBeProcessed) external
            onlyAdmin("setGlobalWaitingDurationForOldTokenToBeProcessed: Only admin can change globalWaitingDurationForOldTokenToBeProcessed") {
        _checkGlobalWaitingDurationForOldTokenToBeProcessedRequirements(newGlobalWaitingDurationForOldTokenToBeProcessed);
        _globalWaitingDurationForOldTokenToBeProcessed = newGlobalWaitingDurationForOldTokenToBeProcessed;
    }

    /* ********************************************************************************************** */

    /**
     * @dev See IToBridge.
     */
    function isCurrentlyMintable() public view virtual override returns(bool);

    /**
     * @dev See IToBridge.
     */
    function acquire(
        Origin calldata origin,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment, bytes memory secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) public virtual override nonReentrant {
        Destination memory destination = Destination(block.chainid, _toToken, address(this));

        // Check all requirements to acquire.
        _checkAcquireRequiments(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            commitment, secret,
            requestTimestamp,
            validatorSignature);

        // Mint a new token corresponding to the old one.
        uint256 newTokenId = _mint(tokenOwner, oldTokenInfo.tokenUri);

        // Update all state variables needed.
        _updateStateWhenAcquire(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            newTokenId,
            commitment, secret,
            requestTimestamp,
            validatorSignature);

        // Emit all events needed.
        _emitEventsWhenAcquire(
            origin,
            destination,
            tokenOwner,
            oldTokenInfo,
            newTokenId,
            commitment, secret,
            requestTimestamp,
            validatorSignature);
    }

    /**
     * @dev Check all requirements to acquire new token. If an child contract has more
     * requirements, when overriding, it SHOULD first call super._checkAcquireRequiments(...)
     * then add its own requirements.
     * Parameters are that of "acquire" function plus "destination".
     *
     * Currently the checks are:
     * - ToBridge can mint new token.
     * - Validator's signature.
     * - Validator's commitment.
     * - The new token has not yet been acquired.
     * - The message sender is the token owner.
     * - The commit transaction at FromBridge is finalized.
     */
    function _checkAcquireRequiments(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        bytes32 commitment, bytes memory secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal view virtual {
        // Check mint capability.
        require(isCurrentlyMintable(), "Acquire: Cannot mint new token at the moment");

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
            "Acquire: Invalid validator signature");

        // Verify validator's revealed value.
        require(Commitment.verify(commitment, secret), "Acquire: Commitment and revealed value do not match");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "Acquire: Token has been acquired");

        // By policy, token owners must acquire by themselves.
        require(msg.sender == tokenOwner, "Acquire: Token can only be acquired by its owner");

        // Revert if user did not wait enough time.
        require(block.timestamp > requestTimestamp + _globalWaitingDurationForOldTokenToBeProcessed,
            "Acquire: Elapsed time from request is not enough");
    }

    /**
     * @param commitment The validator's commitment. It uniquely identifies every acquirements.
     * @return true if the token has already been acquired.
     */
    function _isAcquired(bytes32 commitment) internal view returns(bool) {
        return _acquiredRequests[commitment];
    }

    /**
     * @dev Mint new token.
     * @param to The owner of the newly minted token.
     * @param tokenUri The URI of the newly minted token.
     * @return The ID of the newly minted token.
     */
    function _mint(address to, bytes memory tokenUri) internal virtual returns(uint256);

    /**
     * @dev Save or update all the state variables needed.
     * Child contracts MAY override if they had other state variables needing to be saved or updated.
     * In that case, super._updateStateWhenAcquire() MUST be called to keep the parent contracts' state consistent.
     * Parameters are that of "_checkAcquireRequiments" function plus "newTokenId".
     * All values are put in parameter to cover all possible cases.
     *
     * When overriding this function, DO NOT make external call. Preventing reentrancy attack is one reason.
     * Overriding functions MUST only carry out modifications to the contract's storage.
     */
    function _updateStateWhenAcquire(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        uint256 newTokenId,
        bytes32 commitment, bytes memory secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal virtual {
        // Mark request as acquired.
        _markRequestAcquired(commitment);
    }

    /**
     * @dev Mark request as acquired.
     */
    function _markRequestAcquired(bytes32 commitment) internal {        
        _acquiredRequests[commitment] = true;
    }

    /**
     * @dev Emit all the events needed. Child contracts MAY override to emit the events they want.
     * However, super._emitEventsWhenAcquire() SHOULD be called to keep emitting the events of parent contracts.
     * Parameters are the same as "_updateStateWhenAcquire" function. All values are put in parameter
     * to cover all possible events.
     *
     * When overriding this function, DO NOT make external call. Preventing reentrancy attack is one reason.
     * Overriding functions MUST only emit event(s).
     */
    function _emitEventsWhenAcquire(
        Origin calldata origin,
        Destination memory destination,
        address tokenOwner,
        TokenInfo memory oldTokenInfo,
        uint256 newTokenId,
        bytes32 commitment, bytes memory secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal virtual {
        emit Acquire(
            origin.fromChainId,
            origin.fromToken,
            origin.fromBridge,
            tokenOwner,
            newTokenId,
            commitment,
            block.timestamp);
    }
}
