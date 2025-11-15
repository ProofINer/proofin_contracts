// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title ProofAccess - ProofHome 역할 기반 접근 제어 컨트랙트
/// @notice ProofHome 시스템 내의 권한(Role)을 정의하고 제어한다.
contract ProofAccess is AccessControl {
    // ------------------------------------------------------------
    // 🏷️ 역할(Role) 정의
    // ------------------------------------------------------------
    bytes32 public constant TENANT_ROLE = keccak256("TENANT_ROLE");
    bytes32 public constant LANDLORD_ROLE = keccak256("LANDLORD_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    // ------------------------------------------------------------
    // ⚙️ 생성자: 초기 관리자 설정
    // ------------------------------------------------------------
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    // ------------------------------------------------------------
    // 🧾 역할 부여 및 해제
    // ------------------------------------------------------------

    /// @notice 새로운 임차인 주소에 TENANT_ROLE 부여
    function grantTenant(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(TENANT_ROLE, account);
    }

    /// @notice 새로운 임대인 주소에 LANDLORD_ROLE 부여
    function grantLandlord(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(LANDLORD_ROLE, account);
    }

    /// @notice 시스템 내부 컨트랙트(ProofHome, Vault 등)에 SYSTEM_ROLE 부여
    function grantSystem(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(SYSTEM_ROLE, account);
    }

    /// @notice 역할 회수
    function revokeTenant(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(TENANT_ROLE, account);
    }

    function revokeLandlord(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(LANDLORD_ROLE, account);
    }

    // ------------------------------------------------------------
    // 🛡️ 접근 제어용 헬퍼 함수
    // ------------------------------------------------------------

    /// @notice 임차인 전용 접근자
    modifier onlyTenant() {
        require(hasRole(TENANT_ROLE, msg.sender), "Access: Not Tenant");
        _;
    }

    /// @notice 임대인 전용 접근자
    modifier onlyLandlord() {
        require(hasRole(LANDLORD_ROLE, msg.sender), "Access: Not Landlord");
        _;
    }

    /// @notice ProofHome 등 시스템 컨트랙트 전용 접근자
    modifier onlySystem() {
        require(hasRole(SYSTEM_ROLE, msg.sender), "Access: Not System Contract");
        _;
    }

    /// @notice 관리자 전용 접근자
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Access: Not Admin");
        _;
    }
}
