// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SUKUSD.sol";
import "./SukukBond.sol";

contract PlatformManager is AccessControl {
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SHARIA_ADVISOR_ROLE = keccak256("SHARIA_ADVISOR_ROLE");

    SUKUSD public sukusd;
    mapping(address => bool) public registeredSukuks;

    constructor(address _sukusd) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        sukusd = SUKUSD(_sukusd);
    }

    function assignRole(address account, bytes32 role) external onlyRole(MASTER_ROLE) {
        require(role != MASTER_ROLE, "MASTER_ROLE can only be assigned by the contract deployer");
        grantRole(role, account);
    }

    function revokeRole(address account, bytes32 role) external onlyRole(MASTER_ROLE) {
        require(role != MASTER_ROLE, "MASTER_ROLE cannot be revoked");
        _revokeRole(role, account);
    }

    function mintSUKUSD(address to, uint256 amount) external onlyRole(CUSTODIAN_ROLE) {
        sukusd.mint(to, amount);
    }

    function burnSUKUSD(address from, uint256 amount) external onlyRole(CUSTODIAN_ROLE) {
        sukusd.burn(from, amount);
    }

    function registerSukuk(address sukukAddress) external onlyRole(MASTER_ROLE) {
        registeredSukuks[sukukAddress] = true;
    }

    function unregisterSukuk(address sukukAddress) external onlyRole(MASTER_ROLE) {
        registeredSukuks[sukukAddress] = false;
    }
}
