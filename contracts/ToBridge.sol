//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ToNFT.sol";
import "./utils/Commitment.sol";
import "./utils/Signature.sol";

/**
 * @title ToBridge
 * @dev This contract carries out the second part of the process of bridging (converting)
 * user's ERC721 NFTs from another chain to this chain. Both chains are Ethereum-based.
 * The second part is essentially minting new NFTs corresponding to the old ones for users.
 */
contract ToBridge is Ownable, Initializable, ReentrancyGuard {

    struct AcquirementDetail {
        address acquirer;
        uint256 oldTokenId;
        uint256 newTokenId;
        string  tokenUri;
        uint256 requestTimestamp;
        uint256 waitingDurationForOldTokenToBeProcessed;
        uint256 timestamp;
    }

    /**
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     *
     * - fromBridge: Address of the contract that carries out the first part of the bridging process.
     * fromToken contract and fromBridge contract must be on the same chain.
     *
     * - toToken: Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     *
     * - toBridge: Address of this contract.
     * toToken contract and toBridge contract must be on the same chain.
     *
     * - validator: (Blockchain) Address of the validator that confirms request on the other chain
     * and provides user signature to obtain the new token on this chain.
     *
     * - globalWaitingDurationForOldTokenToBeProcessed: The duration the token owner needs to wait
     * in order to acquire, starting from request's timestamp determined by the validator.
     * This is to ensure that the "commit" transaction on the old chain is finalized.
     */
    address public  fromToken;
    address public  fromBridge;
    ToNFT   public  toToken;
    address public  toBridge;
    address public  validator;
    uint256 public  globalWaitingDurationForOldTokenToBeProcessed;

    bool    internal _initialized = false;

    /**
     * Mapping from validator's commitment to acquirement.
     * An acquirement will only be stored if a transaction call to "acquire" function succeeds.

     * Even if there were multiple tokens with same token ID requested to be bridged,
     * the commitment would be different each time (with high probability). Therefore commitment
     * could be used as an identity for every requests and acquirements.
     */
    mapping(bytes32 => AcquirementDetail) private _acquirements;

    event Acquire(
        address indexed acquirer,
        uint256 indexed oldTokenId,
        uint256         newTokenId,
        string          tokenUri,
        bytes32 indexed commitment,
        uint256         requestTimestamp,
        uint256         waitingDurationForOldTokenToBeProcessed,
        uint256         acquirementTimestamp);

    modifier onlyInitialized() {
        require(_initialized, "ToBridge: Contract is not initialized");
        _;
    }

    /**
     * @dev To be called immediately after contract deployment. Replaces constructor.
     */
    function initialize(
        address fromToken_,
        address fromBridge_,
        address toToken_,
        address validator_,
        uint256 globalWaitingDurationForOldTokenToBeProcessed_
    ) public virtual onlyOwner initializer {
        fromToken = fromToken_;
        fromBridge = fromBridge_;
        validator = validator_;
        globalWaitingDurationForOldTokenToBeProcessed = globalWaitingDurationForOldTokenToBeProcessed_;

        toToken = ToNFT(toToken_);
        toBridge = address(this);

        _initialized = true;
    }

    /**
     * @dev "validator" setter
     */
    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }

    /**
     * @dev "globalWaitingDurationForOldTokenToBeProcessed" setter
     */
    function setGlobalWaitingDurationForOldTokenToBeProcessed(uint256 newGlobalWaitingDurationForOldTokenToBeProcessed) external onlyOwner {
        globalWaitingDurationForOldTokenToBeProcessed = newGlobalWaitingDurationForOldTokenToBeProcessed;
    }

    /**
     * @dev This function is called by users to get new token corresponding to the old one.
     * @param tokenOwner The owner of the old token.
     * @param tokenId The ID of the old token.
     * @param tokenUri The URI of the old token.
     * @param commitment The validator's commitment.
     * @param secret The validator's revealed value.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param validatorSignature This signature was signed by the validator after verifying
     * that the requester is the token's owner and FromBridge is approved on this token.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     */
    function acquire(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, bytes calldata secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) external onlyInitialized nonReentrant {
        // Check all requirements to acquire.
        _checkAcquireRequiments(
            tokenOwner, tokenId,
            tokenUri,
            commitment, secret,
            requestTimestamp,
            validatorSignature);

        // Mint a new token corresponding to the old one.
        uint256 newTokenId = _mint(tokenOwner, tokenUri);

        // Rename variables for readability.
        address acquirer = tokenOwner;
        uint256 oldTokenId = tokenId;
        uint256 waitingDurationForOldTokenToBeProcessed = globalWaitingDurationForOldTokenToBeProcessed;
        uint256 acquirementTimestamp = block.timestamp;

        // Save acquirement.
        _saveAcquirement(
            acquirer,
            oldTokenId, newTokenId,
            tokenUri, commitment,
            requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            acquirementTimestamp);

        // Emit event.
        emit Acquire(
            acquirer,
            oldTokenId, newTokenId,
            tokenUri, commitment,
            requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            acquirementTimestamp);
    }

    /**
     * @dev Check all requirements to acquire new token. If an inheriting contract has more
     * requirements, when overriding it should first call super._checkAcquireRequiments(...)
     * then add its own requirements.
     * Parameters are the same as "acquire" function.
     *
     * Currently the checks are:
     * - Validator's signature.
     * - Validator's commitment.
     * - The new token has not yet been acquired.
     * - The message sender is the token owner.
     * - The commit transaction at FromBridge is finalized.
     */
    function _checkAcquireRequiments(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, bytes calldata secret,
        uint256 requestTimestamp,
        bytes memory validatorSignature
    ) internal view virtual {
        // Verify validator's signature.
        require(
            _verifyValidatorSignature(
                tokenOwner, tokenId,
                tokenUri,
                commitment, requestTimestamp,
                validatorSignature),
            "Acquire: Invalid validator signature");

        // Verify validator's revealed value.
        require(Commitment.verify(commitment, secret), "Acquire: Commitment and revealed value do not match");

        // The new token must not have been acquired.
        require(!_isAcquired(commitment), "Acquire: Token has been acquired");

        // By policy, token owners must acquire by themselves.
        require(msg.sender == tokenOwner, "Acquire: Token can only be acquired by its owner");

        // Revert if user did not wait enough time.
        require(block.timestamp > requestTimestamp + globalWaitingDurationForOldTokenToBeProcessed,
            "Acquire: Elapsed time from request is not enough");
    }

    /**
     * @dev Mint new token.
     * @param to The owner of the newly minted token.
     * @param tokenUri The URI of the newly minted token.
     * @return The ID of the newly minted token.
     */
    function _mint(address to, string memory tokenUri) internal virtual returns (uint256) {
        uint256 tokenId = _findAvailableTokenId(toToken);

        toToken.mint(to, tokenId, tokenUri);

        return tokenId;
    }

    /**
     * @dev Utility function to help find an ID that is currently available (not owned),
     * in order to mint new token.
     * @param token The ERC721 token in which the ID is looked up.
     * @return An available token ID.
     */
    function _findAvailableTokenId(IERC721 token) internal view virtual returns (uint256) {
        uint256 tokenId;
        uint256 i = 0;
        
        while (true) {
            // Generate somewhat hard-to-collide ID.
            tokenId = uint256(keccak256( abi.encodePacked(address(token), block.timestamp, i) ));

            // Check if an ID is available (not owned) or not.
            // Because "ERC721._exists" is internal function, use "ERC721.ownerOf" instead.
            // Determine an ID's availability based on whether or not "ownerOf" revert.
            // If an ID is not owned by any non-zero addess, it will revert.
            try token.ownerOf(tokenId) {
                i++;
            }
            catch {
                return tokenId;
            }
        }

        // Warning suppressing purpose. Execution will never reach here (NEED TEST).
        return 0;
    }

    /**
     * @dev Save acquirement to contract's storage.
     */
    function _saveAcquirement(
        address acquirer,
        uint256 oldTokenId, uint256 newTokenId,
        string memory tokenUri, bytes32 commitment,
        uint256 requestTimestamp,
        uint256 waitingDurationForOldTokenToBeProcessed,
        uint256 acquirementTimestamp
    ) internal {        
        _acquirements[commitment] = AcquirementDetail(
            acquirer,
            oldTokenId, newTokenId,
            tokenUri,
            requestTimestamp,
            waitingDurationForOldTokenToBeProcessed,
            acquirementTimestamp);
    }

    /**
     * @dev The token had been acquired if and only if the "_acquirements" mapping would
     * have stored non-default values in the AcquirementDetail struct. The default value
     * of every storage slot is 0.
     * @param commitment The validator's commitment. It uniquely identifies every acquirements.
     * @return true if the token has already been acquired.
     */
    function _isAcquired(bytes32 commitment) internal view returns (bool) {
        return _acquirements[commitment].timestamp != 0;
    }

    /**
     * @dev Wrapper of "verifyValidatorSignature" function in "Signature.sol" contract,
     * for code readability purpose in "acquire" function.
     * @param tokenOwner The owner of the requested token.
     * @param tokenId The ID of the requested token.
     * @param tokenUri The URI of the requested token.
     * @param commitment The validator's commitment.
     * @param requestTimestamp The timestamp when the validator received request.
     * @param signature The signature signed by the validator.
     * For message format, see "verifyValidatorSignature" function in "Signature.sol" contract.
     * @return true if the signature is valid with respect to the validator's address
     * and given information.
     */
    function _verifyValidatorSignature(
        address tokenOwner, uint256 tokenId,
        string memory tokenUri,
        bytes32 commitment, uint256 requestTimestamp,
        bytes memory signature
    ) internal view returns (bool) {
        return Signature.verifyValidatorSignature(
            fromToken, fromBridge,
            address(toToken), toBridge,
            tokenOwner, tokenId,
            tokenUri,
            commitment, requestTimestamp,
            validator,
            signature);
    }
}
