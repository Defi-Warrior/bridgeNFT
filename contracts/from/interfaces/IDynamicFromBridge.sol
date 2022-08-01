//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IFromBridge.sol";
import "./events/IDynamicFromBridgeEvents.sol";

interface IDynamicFromBridge is IFromBridge, IDynamicFromBridgeEvents {}
