//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IValidatorRevocationAnnouncementReceiver {
    function receiveAnnouncement(address revokedValidator, address newValidator, address revoker) external;
}
