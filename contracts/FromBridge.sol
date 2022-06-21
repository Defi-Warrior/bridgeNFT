//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title FromBridge
 * @dev This contract is used to convert the user's ERC721 NFTs
 * from this chain to another Ethereum-based chain
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
        uint256 tokenId;
        uint256 timestamp;
        TokenState state;
    }

    /**
     * - fromToken: Address of the ERC721 contract that tokens will be convert from.
     * fromToken contract and fromBridge (this contract) must be on the same chain.
     *
     * - fromBridge: Address of this contract.
     *
     * - toToken: Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     *
     * - toBridge: Address of the contract that mints new tokens corresponding to
     * the old ones for users. toToken contract and toBridge contract must be on
     * the same chain.
     *
     * - server: (Blockchain) Address of the server that confirms request and provides
     * user signature to obtain the new token on the other chain.
     *
     * - lockTokenDuration: The duration the token owner needs to wait to claim back
     * the token in case the request is not confirmed by the server.
     */
    ERC721Burnable  public fromToken;
    address         public fromBridge;
    address         public toToken;
    address         public toBridge;
    address         public server;
    uint256         public lockTokenDuration;
    
    /**
     * The list stores all request for all users.
     * A request is uniquely identified by the combination of a user address and a requestId.
     * requestId is the RequestDetail[] array index.
     */
    mapping(address => RequestDetail[]) private _requestList;

    event Request(
        address indexed owner,
        uint256 indexed requestId,
        uint256 indexed tokenId,
        uint256         timestamp);

    event Burn(
        address indexed owner,
        uint256 indexed requestId,
        uint256 indexed tokenId,
        uint256         timestamp,
        bytes           serverSignature);

    modifier onlyServer(string memory errorMessage) {
        require(msg.sender == server, errorMessage);
        _;
    }

    constructor() {}

    function initialize(
        address fromTokenAddr_,
        address toTokenAddr_,
        address toBridgeAddr_,
        uint256 lockTokenDuration_
    ) external initializer {
        fromToken = ERC721Burnable(fromTokenAddr_);
        toToken = toTokenAddr_;
        toBridge = toBridgeAddr_;
        lockTokenDuration = lockTokenDuration_;

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
     * @dev The first function the user needs to call if he/she wished to
     * convert the NFT with ID "tokenId" to the other chain. The old NFT (on
     * this chain) will be transfered to the bridge if this transaction is successfully
     * executed.
     * @param tokenId The token's ID
     */
    function request(uint256 tokenId) external {
        require(fromToken.ownerOf(tokenId) == msg.sender, "The token is not owned by message sender");
        address tokenOwner = msg.sender;

        // Get requestId for this request
        uint256 requestId = _requestList[tokenOwner].length;

        // Transfer NFT to bridge in order to lock NFT
        fromToken.safeTransferFrom(tokenOwner, address(this), tokenId);

        // Save request
        uint256 requestTimestamp = block.timestamp;
        _requestList[tokenOwner][requestId] = RequestDetail(tokenId, requestTimestamp, TokenState.LOCKED);

        // Emit event for server to listen
        emit Request(tokenOwner, requestId, tokenId, requestTimestamp);
    }

    /**
     * @dev This function is called only by the server to confirm the request.
     * The token will be burned if this transaction is successfully executed.
     * @param tokenOwner The owner of the token in request
     * @param requestId The request's ID
     * @param signature This signature was signed by the server after the server
     * listened to the Request event. The token owner will use this signature to
     * claim a new token (which shall be identical to the old one) on the other chain.
     * SIGNATURE FORMAT:
     *      "ConfirmNftBurned" || fromToken || fromBridge || toToken || toBridge ||
     *      tokenOwner || requestId || tokenId || timestamp
     */
    function confirm(
        address tokenOwner,
        uint256 requestId,
        bytes memory signature
    ) external onlyServer("Only server is allowed to confirm request") {
        // Retrieve request's detail from tokenOwner and requestId
        RequestDetail storage requestDetail = _requestList[tokenOwner][requestId];

        // Revert if the token is in BURNED or RETURNED state
        require(requestDetail.state == TokenState.LOCKED, "Request is already finalized");

        // Verify if server has confirmed (seen) this request (by signing it).
        // This verification is also the verification if the owner
        // would be able to obtain the new token on the other chain
        bytes memory message = abi.encodePacked("ConfirmNftBurned",
            address(fromToken), address(this),
            toToken, toBridge,
            tokenOwner, requestId,
            requestDetail.tokenId, requestDetail.timestamp
        );
        require(_verifySignature(server, message, signature), "Invalid signature");

        // Permanently burn the token
        fromToken.burn(requestDetail.tokenId);

        // Update the state
        requestDetail.state = TokenState.BURNED;

        // Emit event for user (frontend) to retrieve signature and then use it
        // to obtain new token on the other chain.
        emit Burn(tokenOwner, requestId, requestDetail.tokenId, requestDetail.timestamp, signature);
    }

    function claimBack(uint256 requestId) external {
        
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

    function _verifySignature(
        address signer,
        bytes memory message,
        bytes memory signature
    ) internal view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer, keccak256(message), signature);
    }
}
