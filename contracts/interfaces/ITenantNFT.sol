// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITenantNFT {
    function mintTenantNFT(address landlord, string memory ipfsCID, uint256 deposit) external payable;
    function totalMinted() external view returns (uint256);
    function getLeaseInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 tokenId_,
            address tenant,
            address landlord,
            uint256 deposit,
            string memory ipfsCID,
            uint8 status
        );
}
