//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./utils/Signature.sol";

/**
 * @title FromBridge
 * @dev This contract carries out the first part of the process of bridging (converting)
 * user's ERC721 NFTs from this chain to another chain. Both chains are Ethereum-based.
 * The first part is essentially committing (by validator) and processing NFTs.
 * The processing action is either permanent burning or holding custody of the token,
 * depending on implementation.
 */
contract FromBridge is Ownable, Initializable {     

    /**
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     *
     * - fromBridge: Address of this contract.
     * fromToken contract and fromBridge contract must be on the same chain.
     *
     * - toToken: Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     *
     * - toBridge: Address of the contract that carries out the second part of the bridging process.
     * toToken contract and toBridge contract must be on the same chain.
     *
     * - validator: (Blockchain) Address of the validator that provides owner signature
     * and "secret" to obtain the new token on the other chain.
     */
    ERC721Burnable  public      fromToken;
    address         public      fromBridge;
    address         public      toToken;
    address         public      toBridge;
    address         public      validator;

    /**
     * Boolean flag to determine whether this contract has been initialized or not.
     * "commit" function is blocked if not initialized.
     */
    bool private _initialized = false;

    event Commit(
        address indexed tokenOwner,
        uint256 indexed tokenId,
        bytes32         commitment,
        uint256         requestTimestamp,
        bytes           validatorSignature);

    modifier onlyInitialized() {
        require(_initialized, "FromBridge: Contract is not initialized");
        _;
    }

    modifier onlyValidator(string memory errorMessage) {
        require(msg.sender == validator, errorMessage);
        _;
    }

    /**
     * @dev To be called immediately after contract deployment. Replaces constructor.
     *
     * Guide for overriding and overloading this function:
     * - MUST have "onlyOwner" and "initializer" modifier.
     * - MUST NOT call super.initialize() (for overriding).
     * - MUST initialize all state variables initialized by this function.
     * - After that do whatever needed things for its state variables' initialization.
     * - MUST call _finishInitialization() at the end of the function.
     */
    function initialize(
        address fromToken_,
        address toToken_,
        address toBridge_,
        address validator_
    ) public virtual onlyOwner initializer {
        toToken = toToken_;
        toBridge = toBridge_;
        validator = validator_;

        fromToken = ERC721Burnable(fromToken_);
        fromBridge = address(this);
        
        _finishInitialization();
    }

    /**
     * @dev This function MUST be called in every "initialize" function, including
     * overriding and overloading function, at the end of the function.
     */
    function _finishInitialization() internal onlyInitializing {
        _initialized = true;
    }

    /**
     * @dev "validator" setter
     */
    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }

    /**
     * @dev This function is called only by the validator to submit the commitment
     * and process the token at the same time. The token will be processed if this transaction
     * is successfully executed. The processing action is either permanent burning or holding
     * custody of the token, depending on implementation.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param ownerSignature This signature is signed by the token's owner, and is the prove
     * that the owner indeed requested the token to be bridged.
     * For message format, see "verifyOwnerSignature" function in "Signature.sol" contract.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * The owner will use this signature at ToBridge to acquire or claim a new token
     * (which shall be identical to the old one) on the other chain.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function commit(
        address tokenOwner, uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) external onlyInitialized onlyValidator("Commit: Only validator is allowed to commit") {
        // Check all requirements to commit.
        _checkCommitRequirements(
            tokenOwner, tokenId,
            commitment, requestTimestamp,
            ownerSignature, validatorSignature);

        // Process the token.
        _processToken(tokenId);

        // Emit event for owner (frontend) to retrieve commitment, timestamp and signature.
        emit Commit(tokenOwner, tokenId, commitment, requestTimestamp, validatorSignature);
    }

    /**
     * @dev Check all requirements of the commit process. If an inheriting contract has more
     * requirements, when overriding, it SHOULD first call super._checkCommitRequirements(...)
     * then add its own requirements.
     * Parameters are the same as "commit" function.
     *
     * Currently the checks are:
     * - Owner's signature.
     * - Validator's signature.
     * - "tokenId"'s owner is "tokenOwner".
     * - FromBridge is approved on "tokenId".
     * - The request timestamp determined by the validator is in the past.
     */
    function _checkCommitRequirements(
        address tokenOwner, uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory ownerSignature, bytes memory validatorSignature
    ) internal view virtual {
        // Verify owner's signature.
        require(
            _verifyOwnerSignature(
                tokenOwner, tokenId,
                ownerSignature),
            "Commit: Invalid owner signature");

        // Verify validator's signature.
        require(
            _verifyValidatorSignature(
                tokenOwner, tokenId,
                commitment, requestTimestamp,
                validatorSignature),
            "Commit: Invalid validator signature");

        // Check ownership.
        require(fromToken.ownerOf(tokenId) == tokenOwner,
            "Commit: The token's owner is incorrect");

        // Check approval.
        require(fromToken.getApproved(tokenId) == fromBridge,
            "Commit: FromBridge is not approved on token ID");

        // Check request timestamp's validity (i.e. occured in the past).
        require(block.timestamp > requestTimestamp,
            "Commit: Request timestamp must be in the past");
    }

    /**
     * @dev Wrapper of "verifyOwnerSignature" function in "Signature.sol" contract,
     * for code readability purpose in "_checkCommitRequirements" function.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param signature The signature signed by the token's owner.
     * For message format, see "verifyOwnerSignature" function in "Signature.sol" contract.
     * @return true if the signature is valid with respect to the owner's address
     * and given information.
     */
    function _verifyOwnerSignature(
        address tokenOwner, uint256 tokenId,
        bytes memory signature
    ) internal view returns (bool) {
        return Signature.verifyOwnerSignature(
            address(fromToken), fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            signature);
    }

    /**
     * @dev Wrapper of "verifyValidatorSignature" function in "Signature.sol" contract,
     * for code readability purpose in "_checkCommitRequirements" function.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param signature The signature signed by the validator.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     * @return true if the signature is valid with respect to the validator's address
     * and given information.
     */
    function _verifyValidatorSignature(
        address tokenOwner, uint256 tokenId,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory signature
    ) internal view returns (bool) {
        // Retrieve tokenURI to gather all necessary materials to craft signed message.
        string memory tokenUri = fromToken.tokenURI(tokenId);

        return Signature.verifyValidatorSignature(
            address(fromToken), fromBridge,
            toToken, toBridge,
            tokenOwner, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            validator,
            signature);
    }

    /**
     * @dev Process the token by burning it. Inheriting contracts could perform different actions
     * by overriding this function. For example, if the bridging process allows the owner to
     * get the token back, the processing action will be transfer the token to FromBridge.
     */
    function _processToken(uint256 tokenId) internal virtual {
        fromToken.burn(tokenId);
    }
}
