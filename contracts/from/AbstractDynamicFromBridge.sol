//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractFromBridge.sol";

/**
 * @title AbstractDynamicFromBridge
 * @dev The version of FromBridge that supports any FromToken with standard URI,
 * therefore can "dynamically" work with multiple ERC721 tokens.
 *
 * Due to the "_getTokenUri" function in AbstractFromBridge already has a default implementation,
 * this contract does not need to override that function and so is the same as AbstractFromBridge.
 * The purpose of making a child contract is to maintain the symmetry (dynamic vs static)
 * of the inheritance tree. Otherwise we would have AbstractStaticFromBridge derives from
 * AbstractDynamicFromBridge. :(
 */
abstract contract AbstractDynamicFromBridge is AbstractFromBridge {}
