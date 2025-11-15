// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ProofTypes - ProofHome의 공통 데이터 구조 및 이벤트 정의
/// @notice 모든 컨트랙트(TenantNFT, LandlordVerifier, DepositVault, ProofHome)에서 import하여 사용
library ProofTypes {
    // ------------------------------------------------------------
    // 📊 상태 정의 (Status Enums)
    // ------------------------------------------------------------

    /// @notice 임대차 계약의 상태를 나타내는 열거형
    enum VerifyStatus {
        Requested,      // 임차인이 계약 요청 (NFT 아직 발행 안됨)
        Verified,       // 임대인 검증 완료 (NFT 발행 준비)
        Active,         // NFT 발행 완료, 계약 활성화
        Completed,      // 보증금 반환 완료
        Rejected        // 임대인 검증 거절 (보증금 반환 없음)
    }

    // ------------------------------------------------------------
    // 🧾 임대차 계약 구조체 (NFT 기준)
    // ------------------------------------------------------------
    struct Lease {
        uint256 tokenId;        // NFT 고유 ID
        address tenant;         // 임차인 주소
        address landlord;       // 임대인 주소
        uint256 deposit;        // 보증금 금액 (wei)
        string ipfsCID;         // IPFS CID (영상·사진·계약서)
        VerifyStatus status;    // 현재 상태
    }

    // ------------------------------------------------------------
    // 💰 보증금 정보 구조체 (DepositVault)
    // ------------------------------------------------------------
    struct DepositInfo {
        uint256 amount;         // 예치 금액
        bool released;          // 반환 여부
        address tenant;         // 예치자(임차인)
        address landlord;       // 임대인
    }

    // ------------------------------------------------------------
    // 🪄 이벤트 정의 (공통 이벤트 키)
    // ------------------------------------------------------------
    event ContractCreated(
        uint256 indexed tokenId,
        address indexed tenant,
        address indexed landlord,
        uint256 deposit,
        string ipfsCID
    );

    event PreApproved(
        address indexed tenant,
        address indexed landlord
    );

    event Verified(
        uint256 indexed tokenId,
        address indexed landlord,
        bool approved,
        string comment
    );

    event DepositAdded(
        uint256 indexed tokenId,
        uint256 amount,
        address indexed tenant
    );

    event DepositReleased(
        uint256 indexed tokenId,
        uint256 amount,
        address indexed tenant
    );

    event LeaseFinalized(
        uint256 indexed tokenId,
        address indexed tenant,
        address indexed landlord
    );
}
