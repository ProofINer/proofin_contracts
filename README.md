# ProofIn – 블록체인 기반 임대차 검증 DApp

> 입주 때 집 상태를 담은 문서를 NFT로 민팅해, 위변조할 수 없는 기록으로 보증금 분쟁을 줄이는 DApp — 스마트 컨트랙트

**ProofIn**은 입주 때 집 상태를 담은 문서를 NFT로 발행해 위변조를 막고, 집주인 검증과 보증금 예치·반환을 스마트 컨트랙트로 처리하는 DApp입니다.

### 핵심 특징
- **🔐 블록체인 기반 검증**: 임대차 계약 데이터를 온체인에 기록하여 위변조 불가능한 검증 시스템 구축
- **💰 투명한 보증금 관리**: 스마트 컨트랙트를 통한 자동화된 보증금 예치 및 반환 프로세스
- **🎫 NFT 기반 계약 증명**: 검증된 임대차 계약을 NFT로 발행하여 소유권 증명 및 이력 관리
- **⚡ 자동화된 워크플로우**: 임대인 승인 시 자동으로 NFT 발행 및 계약 활성화 처리

### 기술 스택
**Smart Contract Layer**
- `Solidity 0.8.20`: 스마트 컨트랙트 개발
- `Hardhat`: 개발 환경 및 테스트 프레임워크
- `OpenZeppelin`: 검증된 컨트랙트 라이브러리 (ERC721, Ownable, ReentrancyGuard)
- `ethers.js v6`: 블록체인 인터랙션

**Infrastructure** (Backend 연동 준비)
- Multi-chain 지원: Ethereum Sepolia, Base, Sonic, Monad 테스트넷
- AWS Lambda와 연동 가능한 이벤트 기반 아키텍처
- IPFS 연동을 통한 메타데이터 저장 구조
