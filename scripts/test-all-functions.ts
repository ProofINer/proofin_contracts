import { ethers } from "hardhat";

async function main() {
  console.log("🧪 ProofIn 시스템 테스트 시작...\n");

  // 먼저 배포부터 하겠습니다
  console.log("🚀 컨트랙트 배포 중...\n");

  const [deployer, tenant, landlord] = await ethers.getSigners();
  console.log("👥 테스트 계정들:");
  console.log("  Deployer:", deployer.address);
  console.log("  Tenant:", tenant.address);
  console.log("  Landlord:", landlord.address);

  // 1. TenantNFT 배포
  const TenantNFT = await ethers.getContractFactory("TenantNFT");
  const tenantNFT = await TenantNFT.deploy();
  await tenantNFT.waitForDeployment();
  const tenantNFTAddress = await tenantNFT.getAddress();
  console.log("🏷 TenantNFT 배포 완료:", tenantNFTAddress);

  // 2. LandlordVerifier 배포
  const LandlordVerifier = await ethers.getContractFactory("LandlordVerifier");
  const landlordVerifier = await LandlordVerifier.deploy();
  await landlordVerifier.waitForDeployment();
  const landlordVerifierAddress = await landlordVerifier.getAddress();
  console.log("👨‍💼 LandlordVerifier 배포 완료:", landlordVerifierAddress);

  // 3. DepositVault 배포
  const DepositVault = await ethers.getContractFactory("DepositVault");
  const depositVault = await DepositVault.deploy();
  await depositVault.waitForDeployment();
  const depositVaultAddress = await depositVault.getAddress();
  console.log("🏦 DepositVault 배포 완료:", depositVaultAddress);

  // 4. ProofIn 메인 컨트랙트 배포
  const ProofIn = await ethers.getContractFactory("ProofIn");
  const proofIn = await ProofIn.deploy();
  await proofIn.waitForDeployment();
  const proofInAddress = await proofIn.getAddress();
  console.log("🎯 ProofIn 배포 완료:", proofInAddress);

  // 5. 초기화 설정
  console.log("\n⚙️ 컨트랙트 초기화 중...");
  
  await proofIn.initializeContracts(
    tenantNFTAddress,
    landlordVerifierAddress,
    depositVaultAddress
  );
  console.log("✅ ProofIn에 컨트랙트 주소들 연결");

  await tenantNFT.setProofInAddress(proofInAddress);
  console.log("✅ TenantNFT에 ProofIn 주소 설정");

  await tenantNFT.setDepositVault(depositVaultAddress);
  console.log("✅ TenantNFT에 DepositVault 주소 설정");

  await depositVault.transferOwnership(proofInAddress);
  console.log("✅ DepositVault 소유권을 ProofIn으로 이전");

  console.log("\n📋 1단계: 초기 상태 조회");
  console.log("==================================");
  
  // 초기 상태 조회
  const totalMinted = await tenantNFT.totalMinted();
  console.log("총 민팅된 NFT:", totalMinted.toString());

  console.log("\n� 2단계: 계약 요청 (대기 상태 등록)");
  console.log("==================================");
  
  const depositAmount = ethers.parseEther("1.0"); // 1 ETH 보증금
  const ipfsCID = "QmYourIPFSHashHere123456789";
  
  // 임차인이 계약 요청 (NFT 아직 발행 안됨)
  const createLeaseTx = await proofIn.connect(tenant).createLease(
    landlord.address,
    ipfsCID,
    depositAmount,
    { value: depositAmount }
  );
  const receipt = await createLeaseTx.wait();
  console.log("✅ 계약 요청 완료 (대기 상태로 등록, NFT 아직 미발행)");
  
  // 요청 ID 추출 (이벤트에서)
  const requestId = 1; // 첫 번째 요청이므로 1
  console.log("📋 요청 ID:", requestId);

  console.log("\n🔍 3단계: 대기 상태 확인");
  console.log("==================================");
  
  // 총 민팅 개수 확인 (아직 0이어야 함)
  const totalMintedBeforeVerification = await tenantNFT.totalMinted();
  console.log("검증 전 총 민팅 개수:", totalMintedBeforeVerification.toString());
  
  // 대기 중인 계약 정보 확인
  const pendingLease = await proofIn.pendingLeases(requestId);
  console.log("📋 대기 중인 계약:", {
    tenant: pendingLease.tenant,
    landlord: pendingLease.landlord,
    deposit: ethers.formatEther(pendingLease.deposit) + " ETH",
    status: pendingLease.status.toString(), // 0 = Requested
    exists: pendingLease.exists
  });
  
  console.log("\n🏠 4단계: 임대인 검증");
  console.log("==================================");
  
  // 임대인이 계약 요청을 검증하여 승인
  const verifyTx = await proofIn.connect(landlord).verifyLeaseRequest(
    requestId,
    true, // 승인
    "Contract approved by landlord"
  );
  await verifyTx.wait();
  console.log("✅ 임대인 검증 완료 (승인)");
  
  // 검증 후 상태 확인
  const verifiedLease = await proofIn.pendingLeases(requestId);
  console.log("📋 검증 후 상태:", {
    status: verifiedLease.status.toString() // 1 = Verified
  });

  console.log("\n🎯 5단계: NFT 자동 발행 확인 (검증과 동시에 자동 발행됨)");
  console.log("==================================");
  
  // 검증이 완료되면서 자동으로 NFT가 발행되었음
  console.log("✅ NFT 자동 발행 완료 (verifyLeaseRequest와 동시 실행)");
  
  // 발행된 tokenId는 1이 됨 (첫 번째 NFT)
  const tokenId = 1;
  
  // 총 민팅 개수 확인
  const newTotalMinted = await tenantNFT.totalMinted();
  console.log("새로운 총 민팅 개수:", newTotalMinted.toString());
  
  // NFT 정보 조회
  const leaseInfo = await tenantNFT.getLeaseInfo(tokenId);
  console.log("📄 NFT 계약 정보:", {
    tokenId: leaseInfo.tokenId.toString(),
    tenant: leaseInfo.tenant,
    landlord: leaseInfo.landlord,
    deposit: ethers.formatEther(leaseInfo.deposit) + " ETH",
    ipfsCID: leaseInfo.ipfsCID,
    status: leaseInfo.status.toString()
  });

  // 보증금 정보 조회
  const depositInfo = await depositVault.getDepositInfo(tokenId);
  console.log("💰 보증금 정보:", {
    amount: ethers.formatEther(depositInfo.amount) + " ETH",
    released: depositInfo.released,
    tenant: depositInfo.tenant,
    landlord: depositInfo.landlord
  });

  // NFT 소유자 확인
  const nftOwner = await tenantNFT.ownerOf(tokenId);
  console.log("🏷 NFT 소유자:", nftOwner);
  console.log("임차인과 일치:", nftOwner === tenant.address);

  console.log("\n✅ 6단계: 계약 완료 후 보증금 반환 테스트");
  console.log("==================================");
  
  // 임대인이 계약 완료 검증 (기존 시스템 사용)
  const completeVerifyTx = await landlordVerifier.connect(landlord).verifyRecord(
    tokenId,
    true, // 승인
    "Contract completed successfully"
  );
  await completeVerifyTx.wait();
  console.log("✅ 임대인 완료 검증");
  
  // 검증 결과 확인
  const verificationPassed = await landlordVerifier.verificationPassed(tokenId);
  console.log("완료 검증 통과:", verificationPassed);
  
  // 보증금 반환 (누구나 실행 가능)
  const finalizeTx = await proofIn.finalizeLease(tokenId);
  await finalizeTx.wait();
  console.log("✅ 보증금 반환 완료");
  
  // 최종 보증금 상태 확인
  const finalDepositInfo = await depositVault.getDepositInfo(tokenId);
  console.log("💰 최종 보증금 상태:", {
    amount: ethers.formatEther(finalDepositInfo.amount) + " ETH",
    released: finalDepositInfo.released
  });

  console.log("\n🎉 새로운 플로우 테스트 완료!");
  console.log("==================================");
  console.log("✅ 컨트랙트 배포");
  console.log("✅ 계약 요청 (대기 상태 등록)");
  console.log("✅ 임대인 검증 (승인)");
  console.log("✅ NFT 발행 (검증 통과 후)");
  console.log("✅ 계약 완료 검증");
  console.log("✅ 보증금 반환");
  console.log("");
  console.log("🔄 자동화된 플로우:");
  console.log("   1️⃣ Tenant → 계약 요청 (NFT 아직 없음)");
  console.log("   2️⃣ Landlord → 검증 & 승인");
  console.log("   3️⃣ System → 자동 NFT 발행 (검증과 동시)");
  console.log("   4️⃣ Contract → 즉시 활성화");
  console.log("   5️⃣ Completion → 보증금 반환");
  
  console.log("\n📝 배포된 컨트랙트 주소들:");
  console.log("  TenantNFT:", tenantNFTAddress);
  console.log("  LandlordVerifier:", landlordVerifierAddress);
  console.log("  DepositVault:", depositVaultAddress);
  console.log("  ProofIn:", proofInAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ 테스트 실패:", error);
    process.exit(1);
  });