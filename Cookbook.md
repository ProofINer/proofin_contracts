cd /Users/susie/Desktop/Temp_Laptop3/Solidity_Files/Yn 
mkdir proofin_contracts && cd proofin_contracts
npx hardhat --init

core: 실제 동작 코드 있음
interfaces: 함수 정의만 있음, ABI 참조용으로만 사용됨

proofin_contracts/
├── contracts/
│   ├── ProofIn.sol                     # 메인 컨트랙트 (조정자·이벤트 중심)
│   │
│   ├── core/
│   │   ├── TenantNFT.sol                 # 🧾 임차인 NFT (계약서+IPFS)
│   │   ├── LandlordVerifier.sol          # 🔍 임대인 승인·검증 로직
│   │   ├── DepositVault.sol              # 💰 보증금 예치 및 반환
│   │   ├── ProofTypes.sol                # 📦 구조체·enum·event 정의
│   │   └── ProofAccess.sol (optional)    # 🔐 접근 제어 (onlyTenant, onlyLandlord)
│   │
│   ├── interfaces/
│   │   ├── IProofHome.sol
│   │   ├── ITenantNFT.sol
│   │   ├── ILandlordVerifier.sol
│   │   ├── IDepositVault.sol
│   │   └── IProofTypes.sol (optional)
│   │
│   └── libraries/ (optional)             # hash, string compare 등 공통 유틸
│
├── scripts/
│   └── deploy.ts
├── test/
│   └── ProofHome.test.ts
├── hardhat.config.ts
└── .env

=> 그니까 한 마디로, TenantNFT, LandlordVerifier, DepositVault가 핵심. 3개만 알면 됨.

Tenant          LandlordVerifier         TenantNFT            DepositVault            ProofIn
  |                    |                     |                     |                     |
  | preApproveTenant() |                     |                     |                     |
  |------------------->|                     |                     |                     |
  |                    | emit PreApproved()  |                     |                     |
  |                    |                     |                     |                     |
  | mintTenantNFT()    | isTenantApproved()  |                     |                     |
  |--------------------|-------------------->| deposit()            |                     |
  |                    |                     |-------------------->| emit DepositAdded()  |
  |                    |                     | emit ContractCreated()                     |
  |                    |                     |                     |                     |
  |                    | verifyRecord()      |                     |                     |
  |                    |-------------------->| releaseDeposit()    |                     |
  |                    |                     |-------------------->| emit DepositReleased()|

# 배포
로컬 배포
npx hardhat node
npx hardhat run scripts/deploy.ts --network localhost
npx hardhat console --network localhost
npx hardhat run scripts/test-all-functions.ts --network hardhat
