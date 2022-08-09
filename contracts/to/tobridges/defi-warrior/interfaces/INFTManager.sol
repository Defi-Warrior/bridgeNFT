//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTManager {
    function mint(
        address to,
        uint32[30] memory warriorAttributes,
        uint32[20][6] memory bodypartAttributes
    ) external returns(uint256);
}

/* NFTManager example

contract NFTManager is INFTManager {
    // Add setters require admin right.
    address _toBridge;
    bool _allowMint;

    function receiveAnnouncement(address revokedValidator, address newValidator, address revoker) external {
        require(msg.sender == _toBridge);
        _allowMint = false;
        // ...
    }

    function isCurrentlyMintable() external view returns(bool) {
        // Could be other logic.
        return _allowMint;
    }

    function mint(
        address to,
        uint32[30] memory warriorAttributes,
        uint32[20][6] memory bodypartAttributes
    ) external returns(uint256) {
        require(msg.sender == _toBridge);
        require(_allowMint);
        // ...
    }
}
*/