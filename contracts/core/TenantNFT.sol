// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDepositVault.sol";
import "./ProofTypes.sol";

/// @title TenantNFT - 임차인 계약 증표 NFT 컨트랙트
/// @notice NFT 민팅과 DepositVault로 보증금 자동 예치를 처리
contract TenantNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using ProofTypes for *;

    uint256 private _tokenIds;
    IDepositVault public tenantDepositVault;
    
    address public proofInAddress; // ProofIn 컨트랙트 주소
    
    modifier onlyProofIn() {
        require(msg.sender == proofInAddress, "Only ProofIn contract allowed");
        _;
    }mapping(uint256 => ProofTypes.Lease) public leases;
mapping(uint256 => address) public landlordOf;

event ContractCreated(
    uint256 indexed tokenId,
    address indexed tenant,
    address indexed landlord,
    uint256 deposit,
    string ipfsCID
);

constructor() ERC721("ProofHomeTenantNFT", "PHTN") Ownable(msg.sender) {}

/// @notice 외부 컨트랙트 주소 설정 (ProofIn에서 초기화)
function setDepositVault(address _depositVault) external onlyOwner {
    tenantDepositVault = IDepositVault(_depositVault);
}

/// @notice ProofIn 컨트랙트 주소 설정
function setProofInAddress(address _proofInAddress) external onlyOwner {
    require(_proofInAddress != address(0), "Invalid ProofIn address");
    proofInAddress = _proofInAddress;
}

/// @notice 임차인 NFT 민팅 (ProofIn에서만 호출 가능)
/// @param tenant 실제 임차인 주소 (ProofIn에서 전달)
/// @param landlord 임대인 주소
/// @param ipfsCID 계약서 및 상태 기록이 포함된 IPFS CID
/// @param deposit 보증금 금액 (msg.value로 함께 송금)
function mintTenantNFT(address tenant, address landlord, string memory ipfsCID, uint256 deposit) external payable onlyProofIn returns (uint256) {
    require(msg.value == deposit, "Deposit must match msg.value");
    require(tenant != address(0), "Invalid tenant address");
    require(landlord != address(0), "Invalid landlord address");

    _tokenIds++;
    uint256 tokenId = _tokenIds;

    // NFT 소유자는 tenant (ProofIn에서 전달받은 주소)
    _safeMint(tenant, tokenId);
    _setTokenURI(tokenId, ipfsCID);
    landlordOf[tokenId] = landlord;

    leases[tokenId] = ProofTypes.Lease({
        tokenId: tokenId,
        tenant: tenant,
        landlord: landlord,
        deposit: deposit,
        ipfsCID: ipfsCID,
        status: ProofTypes.VerifyStatus.Active
    });

    // 보증금 예치 (DepositVault로 송금) - 업데이트된 인터페이스 사용
    tenantDepositVault.deposit{value: deposit}(tokenId, tenant, landlord);

    emit ContractCreated(tokenId, tenant, landlord, deposit, ipfsCID);
    
    return tokenId;
}

/// @notice 특정 NFT의 계약 상세 정보 조회
function getLeaseInfo(uint256 tokenId) external view returns (ProofTypes.Lease memory) {
    require(_ownerOf(tokenId) != address(0), "Token does not exist");
    return leases[tokenId];
}

/// @notice 전체 민팅 개수 조회
function totalMinted() external view returns (uint256) {
    return _tokenIds;
}

}
