// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ILandlordVerifier {
    function preApproveTenant(address tenant, string memory comment) external;
    function isTenantApproved(address tenant) external view returns (bool);
    function verifyRecord(uint256 tokenId, bool approved, string memory comment) external;
    function verificationPassed(uint256 tokenId) external view returns (bool);
}
