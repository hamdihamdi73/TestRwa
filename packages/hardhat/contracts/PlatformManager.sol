// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SUKUSD.sol";
import "./SukukBond.sol";

contract PlatformManager is AccessControl {
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    SUKUSD public sukusd;
    mapping(address => bool) public registeredSukuks;

    constructor(address _sukusd) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        sukusd = SUKUSD(_sukusd);
    }

    function createAccount(address account, bytes32 role) external onlyRole(MASTER_ROLE) {
        grantRole(role, account);
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
