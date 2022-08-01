//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../interfaces/IStaticFromBridge.sol";
import "./events/IDefiWarriorFromBridgeEvents.sol";

interface IDefiWarriorFromBridge is IStaticFromBridge, IDefiWarriorFromBridgeEvents {}
