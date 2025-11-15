// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./core/TenantNFT.sol";
import "./core/LandlordVerifier.sol";
import "./core/DepositVault.sol";
import "./core/ProofTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ProofIn - 전체 임대차 신뢰 시스템의 메인 조정 컨트랙트
/// @notice TenantNFT, LandlordVerifier, DepositVault 간의 데이터 및 이벤트를 통합 관리
contract ProofIn is Ownable {
// ----------------------------------------------------------------------
// 📦 상태 변수
// ----------------------------------------------------------------------
address public tenantNFTAddress;
address public landlordVerifierAddress;
address public depositVaultAddress;

// 대기 중인 계약 요청들 (NFT 발행 전)
struct PendingLease {
    uint256 requestId;
    address tenant;
    address landlord;
    string ipfsCID;
    uint256 deposit;
    ProofTypes.VerifyStatus status;
    bool exists;
}

uint256 private _requestIds; // 요청 ID 카운터
mapping(uint256 => PendingLease) public pendingLeases; // requestId → 대기 중인 계약
mapping(uint256 => bool) public leaseCompleted; // tokenId → lease finalized 여부

event LeaseRequested(uint256 indexed requestId, address indexed tenant, address indexed landlord);
event LeaseVerified(uint256 indexed requestId, bool approved, string comment);
event LeaseApproved(uint256 indexed requestId, uint256 indexed tokenId, address indexed tenant, address landlord);
event LeaseRejected(uint256 indexed requestId, address indexed tenant, string reason);
event OwnershipLinked(address tenantNFT, address verifier, address vault);
event LeaseFinalized(uint256 indexed tokenId, address indexed tenant, address indexed landlord);

constructor() Ownable(msg.sender) {}

// ----------------------------------------------------------------------
// ⚙️ 외부 컨트랙트 주소 연결
// ----------------------------------------------------------------------
function initializeContracts(
    address _tenantNFT,
    address _landlordVerifier,
    address _depositVault
) external onlyOwner {
    require(_tenantNFT != address(0), "Invalid TenantNFT address");
    require(_landlordVerifier != address(0), "Invalid LandlordVerifier address");
    require(_depositVault != address(0), "Invalid DepositVault address");

    tenantNFTAddress = _tenantNFT;
    landlordVerifierAddress = _landlordVerifier;
    depositVaultAddress = _depositVault;

    emit OwnershipLinked(_tenantNFT, _landlordVerifier, _depositVault);
}

// ----------------------------------------------------------------------
// 🧾 임대차 계약 요청 (NFT 발행 전 대기 상태 등록)
// ----------------------------------------------------------------------
/// @notice Tenant가 계약을 요청 (NFT는 아직 발행하지 않고 대기 상태로 등록)
function createLease(
    address landlord,
    string memory ipfsCID,
    uint256 deposit
) external payable returns (uint256 requestId) {
    require(msg.value == deposit, "Deposit mismatch");
    require(landlord != address(0), "Invalid landlord address");

    _requestIds++;
    requestId = _requestIds;

    // 대기 상태로 등록 (NFT 아직 발행 안됨)
    pendingLeases[requestId] = PendingLease({
        requestId: requestId,
        tenant: msg.sender,
        landlord: landlord,
        ipfsCID: ipfsCID,
        deposit: deposit,
        status: ProofTypes.VerifyStatus.Requested,
        exists: true
    });

    // 보증금은 컨트랙트에서 보관 (DepositVault로 이동은 NFT 발행 시에)

    emit LeaseRequested(requestId, msg.sender, landlord);
    
    // 백엔드에서는 이 이벤트를 듣고 landlord에게 알람을 보냄
    return requestId;
}

// ----------------------------------------------------------------------
// 🔍 임대인 검증 (대기 중인 계약 요청을 승인/거절)
// ----------------------------------------------------------------------
/// @notice 임대인이 계약 요청을 검증하여 NFT 발행을 승인하거나 거절
function verifyLeaseRequest(
    uint256 requestId,
    bool approved,
    string memory comment
) external {
    PendingLease storage lease = pendingLeases[requestId];
    require(lease.exists, "Request not found");
    require(lease.landlord == msg.sender, "Only landlord can verify");
    require(lease.status == ProofTypes.VerifyStatus.Requested, "Already processed");

    emit LeaseVerified(requestId, approved, comment);
    
    if (approved) {
        // 검증 통과 - 바로 NFT 발행까지 자동 실행
        uint256 tokenId = _mintApprovedNFT(requestId);
        
        // 백엔드에서는 이 이벤트를 듣고 tenant와 landlord에게 NFT 발행 완료 알람을 보냄
        emit LeaseApproved(requestId, tokenId, lease.tenant, lease.landlord);
    } else {
        // 검증 거절 - 보증금 반환하고 요청 제거
        lease.status = ProofTypes.VerifyStatus.Rejected;
        
        // 보증금 즉시 반환
        payable(lease.tenant).transfer(lease.deposit);
        
        emit LeaseRejected(requestId, lease.tenant, comment);
    }

    // LandlordVerifier에도 기록 (기존 시스템과 호환성 위해)
    LandlordVerifier verifier = LandlordVerifier(payable(landlordVerifierAddress));
    verifier.verifyRecord(requestId, approved, comment);
}

// ----------------------------------------------------------------------
// ✅ NFT 발행 및 임대차 활성화 (내부 함수 - 자동 실행)
// ----------------------------------------------------------------------
/// @notice 검증 통과된 요청에 대해 실제 NFT를 발행하고 계약을 활성화 (내부 함수)
function _mintApprovedNFT(uint256 requestId) internal returns (uint256 tokenId) {
    PendingLease storage lease = pendingLeases[requestId];
    
    // NFT 발행
    TenantNFT tenantNFT = TenantNFT(payable(tenantNFTAddress));
    tokenId = tenantNFT.mintTenantNFT{value: lease.deposit}(
        lease.tenant,
        lease.landlord,
        lease.ipfsCID,
        lease.deposit
    );

    // 상태를 Active로 변경
    lease.status = ProofTypes.VerifyStatus.Active;
    
    return tokenId;
}

/// @notice 기존 finalizeLease - 이제 보증금 반환 전용
function finalizeLease(uint256 tokenId) external {
    require(!leaseCompleted[tokenId], "Already finalized");

    LandlordVerifier verifier = LandlordVerifier(payable(landlordVerifierAddress));
    require(verifier.verificationPassed(tokenId), "Verification not approved yet");

    DepositVault vault = DepositVault(payable(depositVaultAddress));
    vault.releaseDeposit(tokenId);

    leaseCompleted[tokenId] = true;

    TenantNFT tenantNFT = TenantNFT(payable(tenantNFTAddress));
    ProofTypes.Lease memory lease = tenantNFT.getLeaseInfo(tokenId);

    emit LeaseFinalized(tokenId, lease.tenant, lease.landlord);
}

// ----------------------------------------------------------------------
// 🔍 헬퍼: 전체 요약 정보 조회
// ----------------------------------------------------------------------
function getLeaseSummary(uint256 tokenId)
    external
    view
    returns (ProofTypes.Lease memory lease, DepositVault.DepositInfo memory depositInfo)
{
    TenantNFT tenantNFT = TenantNFT(payable(tenantNFTAddress));
    DepositVault vault = DepositVault(payable(depositVaultAddress));

    lease = tenantNFT.getLeaseInfo(tokenId);
    (uint256 amount, bool released, address tenant, address landlord) = vault.deposits(tokenId);
    depositInfo = DepositVault.DepositInfo(amount, released, tenant, landlord);
}

}
