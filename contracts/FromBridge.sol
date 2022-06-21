//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
// import "./Nft1.sol";

/**
 * @title FromBridge
 * @dev This contract is used to convert the user's ERC721 NFTs
 * from this chain to another Ethereum-based chain
 */
contract FromBridge is IERC721Receiver, Ownable, Initializable {
    enum TokenStatus { LOCKED, BURNED, RETURNED }

    struct RequestDetail {
        uint256 tokenId;
        uint256 timestamp;
        TokenStatus status;
    }

    ERC721Burnable  public fromToken;
    address         public fromBridge;
    address         public toToken;
    address         public toBridge;
    uint256         public lockNftDuration;
    
    /**
     * The list stores all request for all users.
     * A request is uniquely identified by the combination of a user address and a requestId.
     * requestId is the RequestDetail[] array index.
     */
    mapping(address => RequestDetail[]) private _requestList;

    event Request(address indexed owner,
        uint256 indexed requestId,
        uint256 indexed tokenId,
        uint256 timestamp);

    constructor() {}

    /**
     * @param fromTokenAddr_ Address of the ERC721 contract that tokens will be convert from.
     * fromToken contract and fromBridge (this contract) must be on the same chain.
     * @param toTokenAddr_ Address of the ERC721 contract that tokens will be convert to.
     * fromToken contract and toToken contract might be on different chains.
     * @param toBridgeAddr_ Address of the contract that mints new tokens corresponding to
     * the old ones for users. toToken contract and toBridge contract must be on the same chain.
     * @param lockNftDuration_ The duration the token owner needs to wait to claim back
     * the token in case the request is not confirmed by the server
     */
    function initialize(
        address fromTokenAddr_,
        address toTokenAddr_,
        address toBridgeAddr_,
        uint256 lockNftDuration_
    ) external initializer {
        fromToken = ERC721Burnable(fromTokenAddr_);
        fromBridge = address(this);
        toToken = toTokenAddr_;
        toBridge = toBridgeAddr_;
        lockNftDuration = lockNftDuration_;
    }

    /**
     * @notice The first function the user needs to call if he/she wished to
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
        _requestList[tokenOwner][requestId] = RequestDetail(tokenId, requestTimestamp, TokenStatus.LOCKED);

        // Emit event for backend to listen
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
     *      token owner's address || request's ID || token's ID || request's timestamp
     */
    function confirm(address tokenOwner, uint256 requestId, bytes calldata signature) external {
        RequestDetail storage requestDetail = _requestList[tokenOwner][requestId];
        require(requestDetail.status == TokenStatus.LOCKED, "Request is already finalized");

        // bytes memory message = abi.encodePacked;
    }

    function claimBack(uint256 requestId) external {
        
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _verifySignature(
        address signer,
        bytes calldata message,
        bytes calldata signature
    ) internal view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer, keccak256(message), signature);
    }
}
