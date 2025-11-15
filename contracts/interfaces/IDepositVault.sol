// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDepositVault {
    struct DepositInfo {
        uint256 amount;
        bool released;
        address tenant;
        address landlord;
    }
    
    function deposit(uint256 tokenId, address tenant, address landlord) external payable;
    function releaseDeposit(uint256 tokenId) external;
    function getDepositInfo(uint256 tokenId) external view returns (DepositInfo memory);
}
