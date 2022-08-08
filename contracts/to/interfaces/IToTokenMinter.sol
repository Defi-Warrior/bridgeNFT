//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IToTokenMinter {
    function isCurrentlyMintable() external view returns(bool);
}
