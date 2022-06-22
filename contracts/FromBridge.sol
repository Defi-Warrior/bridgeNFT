//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./utils/Signature.sol";

/**
 * @title FromBridge
 * @dev This contract carries out the first part of the process of bridging (converting)
 * user's ERC721 NFTs from this chain to another chain. Both chains are Ethereum-based.
 * The first part is essentially burning NFTs.
 */
contract FromBridge is IERC721Receiver, Ownable, Initializable {

    /**
     * - LOCKED: After the token is requested by its owner to be converted
     * to the other chain, the corresponding request will be in this state.
     *
     * - BURNED: If the token is in LOCKED state and then FromBridge receives
     * a confirmation (by means of "confirm" function) from the server, if
     * that confirmation transaction is successful, the request will jump to
     * this state.
     *
     * - RETURNED: If the token is in LOCKED state and then FromBridge receives
     * a claim-back request (by means of "claimBack" function) from the owner,
     * if that claim-back transaction is successful, the request will jump to
     * this state.
     */
    enum TokenState { LOCKED, BURNED, RETURNED }

    struct RequestDetail {
        uint256 timestamp;
        uint256 waitingDurationToClaimBack;
        TokenState state;
    }

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
     * - server: (Blockchain) Address of the server that confirms request and provides
     * user signature to obtain the new token on the other chain.
     *
     * - globalWaitingDurationToClaimBack: The duration the token owner needs to wait
     * after requesting bridging token, in order to claim back the token in case the
     * request is not confirmed by the server.
     */
    ERC721Burnable  public fromToken;
    address         public fromBridge;
    address         public toToken;
    address         public toBridge;
    address         public server;
    uint256         public globalWaitingDurationToClaimBack;
    
    /**
     * Mapping from user address -> token's ID -> list of requests from that user on that token's ID.
     * This mapping stores all request for all users.
     * A request (RequestDetail) is uniquely identified by the combination (user address, token's ID, nonce).
     * The nonce is the RequestDetail[] array's index. Therefore, the nonce of one request can
     * be duplicate with the nonce from another request that differs user address or token's ID.
     */
    mapping(address => mapping(uint256 => RequestDetail[])) private _requests;

    event Request(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         requestTimestamp);

    event Burn(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         requestTimestamp,
        uint256         burnTimestamp,
        bytes           serverSignature);

    event Return(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed nonce,
        uint256         requestTimestamp,
        uint256         returnTimestamp);

    modifier onlyServer(string memory errorMessage) {
        require(msg.sender == server, errorMessage);
        _;
    }

    constructor() {}

    function initialize(
        address fromTokenAddr_,
        address toTokenAddr_,
        address toBridgeAddr_,
        uint256 globalWaitingDurationToClaimBack_
    ) external initializer {
        fromToken = ERC721Burnable(fromTokenAddr_);
        toToken = toTokenAddr_;
        toBridge = toBridgeAddr_;
        globalWaitingDurationToClaimBack = globalWaitingDurationToClaimBack_;

        fromBridge = address(this);
        server = msg.sender;
    }

    /**
     * @dev Change server
     */
    function setServer(address newServer) external onlyOwner {
        server = newServer;
    }

    /**
     * @dev Change globalWaitingDurationToClaimBack
     */
    function setGlobalWaitingDurationToClaimBack(uint256 newGlobalWaitingDurationToClaimBack) external onlyOwner {
        globalWaitingDurationToClaimBack = newGlobalWaitingDurationToClaimBack;
    }

    /**
     * @dev The first function the user needs to call if he/she wished to
     * convert the token with ID "tokenId" to the other chain. The old token (on
     * this chain) will be transfered to the bridge if this transaction is successfully
     * executed.
     * @param tokenId The token's ID
     */
    function request(uint256 tokenId) external {
        require(fromToken.ownerOf(tokenId) == msg.sender, "The token is not owned by message sender");
        address tokenOwner = msg.sender;

        // Get new nonce for this request
        uint256 nonce = _requests[tokenOwner][tokenId].length;

        // Transfer token to bridge in order to lock token
        fromToken.safeTransferFrom(tokenOwner, address(this), tokenId);

        // Save request
        uint256 requestTimestamp = block.timestamp;
        _requests[tokenOwner][tokenId].push(RequestDetail(requestTimestamp, globalWaitingDurationToClaimBack, TokenState.LOCKED));

        // Emit event for server to listen
        emit Request(tokenOwner, tokenId, nonce, requestTimestamp);
    }

    /**
     * @dev This function is called only by the server to confirm the request.
     * The token will be burned if this transaction is successfully executed.
     * @param tokenOwner The owner of the token in request
     * @param nonce The request's nonce
     * @param signature This signature was signed by the server after the server
     * listened to the Request event. The token owner will use this signature to
     * claim a new token (which shall be identical to the old one) on the other chain.
     * SIGNATURE FORMAT:
     *      "ConfirmNftBurned" || fromToken || fromBridge || toToken || toBridge ||
     *      tokenOwner || tokenId || nonce || requestTimestamp
     */
    function confirm(
        address tokenOwner,
        uint256 tokenId,
        uint256 nonce,
        bytes memory signature
    ) external onlyServer("Only server is allowed to confirm request") {
        // Retrieve request's detail from tokenOwner, tokenId and nonce
        RequestDetail storage requestDetail = _requests[tokenOwner][tokenId][nonce];

        // Revert if the token is in BURNED or RETURNED state
        require(requestDetail.state == TokenState.LOCKED, "Request is already finalized");

        // Verify if server has confirmed (seen) this request (by signing it).
        // This verification is also the verification if the owner
        // would be able to obtain the new token on the other chain.
        bytes memory message = abi.encodePacked("ConfirmNftBurned",
            address(fromToken), address(this),
            toToken, toBridge,
            tokenOwner, tokenId,
            nonce, requestDetail.timestamp
        );
        require(Signature.verifySignature(server, message, signature), "Invalid signature");

        // Permanently burn the token
        fromToken.burn(tokenId);

        // Update the state
        requestDetail.state = TokenState.BURNED;

        // Emit event for user (frontend) to retrieve signature and then use it
        // to obtain new token on the other chain.
        emit Burn(tokenOwner, tokenId, nonce, requestDetail.timestamp, block.timestamp, signature);
    }

    /**
     * @dev This function is for user to claim back his/her token at will in case the request
     * has not been confirmed by the server for any reason. However, the user must wait a
     * time duration equals to the request's "waitingDurationToClaimBack" after the request
     * transaction in order for the claim back transaction to succeed.
     * @param tokenId The token's ID
     */
    function claimBack(uint256 tokenId) external {
        // Revert if there is no request from user on this token.
        // Additionally, if the msg.sender is not the owner of the token, _requests[tokenOwner][tokenId]
        // returns an empty array, so this statement also reverts.
        require(_requests[msg.sender][tokenId].length > 0, "User has not submitted any request on this token");
        address tokenOwner = msg.sender;
        
        // Retrieve latest request on the token
        uint256 nonce = _requests[tokenOwner][tokenId].length - 1;
        RequestDetail storage requestDetail = _requests[tokenOwner][tokenId][nonce];

        // Only tokens in LOCKED state are allowed to be claimed back. Revert otherwise.
        require(requestDetail.state == TokenState.LOCKED, "The token has already been burned or claimed back");

        // Only allow tokens to be claimed back after "waitingDurationToClaimBack" starting from request timestamp
        require(block.timestamp > requestDetail.timestamp + requestDetail.waitingDurationToClaimBack,
            "Elapsed time from request is not enough");

        // Update state
        requestDetail.state = TokenState.RETURNED;

        // Transfer token back to user
        fromToken.safeTransferFrom(address(this), tokenOwner, tokenId);

        // Emit event
        emit Return(tokenOwner, tokenId, nonce, requestDetail.timestamp, block.timestamp);
    }

    /**
     * @dev Implement this function from IERC721Receiver interface
     * to receive ERC721 token from user. Needed for token-locking
     * functionality.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure virtual override returns (bytes4) {
        // To suppress unused-variable warning
        if (false) { operator; from; tokenId; data; }

        return IERC721Receiver.onERC721Received.selector;
    }
}
