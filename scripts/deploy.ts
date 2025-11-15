import { ethers, network } from "hardhat";

async function main() {
  console.log(`🚀 ProofIn 시스템을 ${network.name} 네트워크에 배포를 시작합니다...\n`);

  // 배포자 계정 정보
  const [deployer] = await ethers.getSigners();
  console.log("📋 배포자 계정:", deployer.address);
  console.log("💰 배포자 잔고:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // ------------------------------------------------------------
  // 1️⃣ TenantNFT
  // ------------------------------------------------------------
  console.log("📦 TenantNFT 배포 중...");
  const TenantNFT = await ethers.getContractFactory("TenantNFT");
  const tenantNFT = await TenantNFT.deploy();
  await tenantNFT.waitForDeployment();
  console.log("✅ TenantNFT 배포 완료:", await tenantNFT.getAddress());

  // ------------------------------------------------------------
  // 2️⃣ LandlordVerifier
  // ------------------------------------------------------------
  console.log("📦 LandlordVerifier 배포 중...");
  const LandlordVerifier = await ethers.getContractFactory("LandlordVerifier");
  const landlordVerifier = await LandlordVerifier.deploy();
  await landlordVerifier.waitForDeployment();
  console.log("✅ LandlordVerifier 배포 완료:", await landlordVerifier.getAddress());

  // ------------------------------------------------------------
  // 3️⃣ DepositVault
  // ------------------------------------------------------------
  console.log("📦 DepositVault 배포 중...");
  const DepositVault = await ethers.getContractFactory("DepositVault");
  const depositVault = await DepositVault.deploy();
  await depositVault.waitForDeployment();
  console.log("✅ DepositVault 배포 완료:", await depositVault.getAddress());

  // ------------------------------------------------------------
  // 4️⃣ ProofIn (Main orchestrator)
  // ------------------------------------------------------------
  console.log("📦 ProofIn 메인 컨트랙트 배포 중...");
  const ProofIn = await ethers.getContractFactory("ProofIn");
  const proofIn = await ProofIn.deploy();
  await proofIn.waitForDeployment();
  console.log("✅ ProofIn 배포 완료:", await proofIn.getAddress());

  // ------------------------------------------------------------
  // 5️⃣ 컨트랙트 간 연결 설정
  // ------------------------------------------------------------
  console.log("\n⚙️ 컨트랙트 간 연결 설정 중...");
  
  const tenantNFTAddr = await tenantNFT.getAddress();
  const verifierAddr = await landlordVerifier.getAddress();
  const vaultAddr = await depositVault.getAddress();
  const proofInAddr = await proofIn.getAddress();

  // 각 컨트랙트에서 직접 연결 설정 (ownership 문제 해결)
  console.log("⚙️ TenantNFT DepositVault 설정 중...");
  const tenantTx = await tenantNFT.setDepositVault(vaultAddr);
  await tenantTx.wait();
  
  console.log("⚙️ TenantNFT ProofIn 주소 설정 중...");
  const proofInSetTx = await tenantNFT.setProofInAddress(proofInAddr);
  await proofInSetTx.wait();
  
  console.log("⚙️ ProofIn 컨트랙트 주소 등록 중...");
  const proofInTx = await proofIn.initializeContracts(tenantNFTAddr, verifierAddr, vaultAddr);
  await proofInTx.wait();
  
  console.log("✅ 모든 컨트랙트 연결 완료");

  // ------------------------------------------------------------
  // 6️⃣ 배포 결과 출력
  // ------------------------------------------------------------
  console.log("\n🎉 배포 완료! 컨트랙트 주소들:");
  console.log("==================================");
  console.log("네트워크:", network.name);
  console.log("체인 ID:", network.config.chainId);
  console.log("----------------------------------");
  console.log("ProofIn (메인):", proofInAddr);
  console.log("TenantNFT:", tenantNFTAddr);
  console.log("LandlordVerifier:", verifierAddr);
  console.log("DepositVault:", vaultAddr);
  console.log("==================================");

  // ------------------------------------------------------------
  // 7️⃣ 검증용 정보 저장
  // ------------------------------------------------------------
  const deploymentInfo = {
    network: network.name,
    chainId: network.config.chainId,
    timestamp: new Date().toISOString(),
    deployer: deployer.address,
    contracts: {
      ProofIn: proofInAddr,
      TenantNFT: tenantNFTAddr,
      LandlordVerifier: verifierAddr,
      DepositVault: vaultAddr
    }
  };

  console.log("\n📋 배포 정보 (JSON):");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  // ------------------------------------------------------------
  // 8️⃣ 컨트랙트 검증 안내
  // ------------------------------------------------------------
  if (network.name !== "hardhat" && network.name !== "localhost") {
    console.log("\n🔍 컨트랙트 검증 명령어:");
    console.log(`npx hardhat verify --network ${network.name} ${proofInAddr}`);
    console.log(`npx hardhat verify --network ${network.name} ${tenantNFTAddr}`);
    console.log(`npx hardhat verify --network ${network.name} ${verifierAddr}`);
    console.log(`npx hardhat verify --network ${network.name} ${vaultAddr}`);
  }
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
