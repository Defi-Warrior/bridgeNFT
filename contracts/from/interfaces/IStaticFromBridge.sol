//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IFromBridge.sol";
import "./events/IStaticFromBridgeEvents.sol";

interface IStaticFromBridge is IFromBridge, IStaticFromBridgeEvents {}
