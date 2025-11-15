// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IProofAccess {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function TENANT_ROLE() external view returns (bytes32);
    function LANDLORD_ROLE() external view returns (bytes32);
    function ADMIN_ROLE() external view returns (bytes32);
    function SYSTEM_ROLE() external view returns (bytes32);
}
