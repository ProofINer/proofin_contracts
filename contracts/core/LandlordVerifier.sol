// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProofTypes.sol";

/// @title LandlordVerifier - 임대인 사후 검증 컨트랙트
/// @notice 임대인은 계약 종료 후 검증을 수행하여 보증금 반환을 결정한다.
contract LandlordVerifier is Ownable {

    mapping(uint256 => bool) public verificationPassed; // tokenId → true/false
    mapping(uint256 => string) public verificationComments; // tokenId → comment

    event Verified(uint256 indexed tokenId, address indexed landlord, bool approved, string comment);

    constructor() Ownable(msg.sender) {}

    // ----------------------------------------------------------------------
    // 📋 계약 종료 후 검증 (사후 검증만 수행)
    // ----------------------------------------------------------------------
    /// @notice 임대인이 계약을 검증하고 보증금 반환 여부를 결정
    /// @param tokenId NFT 토큰 ID
    /// @param approved 승인 여부 (true면 보증금 반환, false면 보증금 유지)
    /// @param comment 검증 코멘트
    function verifyRecord(uint256 tokenId, bool approved, string memory comment) external {
        verificationPassed[tokenId] = approved;
        verificationComments[tokenId] = comment;

        emit Verified(tokenId, msg.sender, approved, comment);
        
        // 참고: 보증금 반환은 ProofIn.finalizeLease()를 통해서만 실행됩니다
        // 이 함수는 검증 결과만 기록하고, 실제 반환은 별도로 호출해야 합니다
    }

    // ----------------------------------------------------------------------
    // 📋 조회 함수들
    // ----------------------------------------------------------------------
    
    /// @notice 특정 토큰의 검증 결과 조회
    function getVerificationResult(uint256 tokenId) external view returns (bool passed, string memory comment) {
        return (verificationPassed[tokenId], verificationComments[tokenId]);
    }
}
