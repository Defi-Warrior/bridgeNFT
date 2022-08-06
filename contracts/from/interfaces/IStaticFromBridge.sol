//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IFromBridge.sol";

interface IStaticFromBridge is IFromBridge {
    function getFromToken() external view returns(address);
}
