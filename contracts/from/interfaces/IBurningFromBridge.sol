//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IFromBridge.sol";
import "./events/IBurningFromBridgeEvents.sol";

interface IBurningFromBridge is IFromBridge, IBurningFromBridgeEvents {}
