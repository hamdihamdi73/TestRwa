// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CHARIAA_COMPLIANCE_ROLE = keccak256("CHARIAA_COMPLIANCE_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
    }

    function addRole(address account, bytes32 role) public onlyRole(MASTER_ROLE) {
        grantRole(role, account);
    }

    function removeRole(address account, bytes32 role) public onlyRole(MASTER_ROLE) {
        revokeRole(role, account);
    }
}