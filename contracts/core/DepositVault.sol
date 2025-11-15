// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProofTypes.sol";

/// @title DepositVault - ProofIn 보증금 에스크로 컨트랙트
/// @notice NFT 단위로 보증금을 예치·보관·반환하며, 승인된 검증 결과에 따라 자동 반환된다.
contract DepositVault is Ownable {
    struct DepositInfo {
        uint256 amount;
        bool released;
        address tenant;
        address landlord;
    }

    mapping(uint256 => DepositInfo) public deposits; // tokenId → 보증금 정보

    event DepositAdded(uint256 indexed tokenId, uint256 amount, address tenant);
    event DepositReleased(uint256 indexed tokenId, uint256 amount, address tenant);

    constructor() Ownable(msg.sender) {}

    /// @notice NFT 민팅 시 호출되어 보증금이 예치된다.
    /// @dev only TenantNFT.sol 에서 호출해야 함
    function deposit(uint256 tokenId, address tenant, address landlord) external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        require(deposits[tokenId].amount == 0, "Deposit already exists");
        require(tenant != address(0), "Invalid tenant address");

        deposits[tokenId] = DepositInfo({
            amount: msg.value,
            released: false,
            tenant: tenant, // 실제 임차인 주소를 매개변수로 받음
            landlord: landlord
        });

        emit DepositAdded(tokenId, msg.value, tenant);
    }

    /// @notice LandlordVerifier가 검증을 승인했을 때 자동으로 호출됨
    /// @param tokenId 해당 NFT의 tokenId
    function releaseDeposit(uint256 tokenId) external onlyOwner {
        DepositInfo storage info = deposits[tokenId];
        require(info.amount > 0, "No deposit stored");
        require(!info.released, "Already released");

        uint256 amount = info.amount;
        info.released = true;
        info.amount = 0;

        // 임차인에게 보증금 반환
        payable(info.tenant).transfer(amount);

        emit DepositReleased(tokenId, amount, info.tenant);
    }

    /// @notice 특정 tokenId의 예치금 상태 확인
    function getDepositInfo(uint256 tokenId) external view returns (DepositInfo memory) {
        return deposits[tokenId];
    }

    /// @notice 예외 상황 대비: ProofIn 컨트랙트 주소 설정
    function authorizeProofIn(address proofInAddress) external onlyOwner {
        transferOwnership(proofInAddress); // ProofIn.sol이 Vault의 owner가 됨
    }
}
