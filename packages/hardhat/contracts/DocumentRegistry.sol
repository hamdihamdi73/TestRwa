// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DocumentRegistry is AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant BONDHOLDER_ROLE = keccak256("BONDHOLDER_ROLE");

    struct Document {
        bytes32 hash;
        address signer;
        uint256 timestamp;
        bool isPublic;
        mapping(bytes32 => bool) allowedRoles;
    }

    mapping(bytes32 => Document) public documents;

    event DocumentSigned(bytes32 indexed documentHash, address indexed signer, uint256 timestamp);
    event DocumentAccessGranted(bytes32 indexed documentHash, bytes32 indexed role);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
    }

    function signDocument(bytes32 documentHash, bool isPublic, bytes32[] memory allowedRoles) external {
        require(hasRole(ISSUER_ROLE, msg.sender) || hasRole(AUDITOR_ROLE, msg.sender) || hasRole(MASTER_ROLE, msg.sender), "Not authorized to sign documents");
        
        Document storage doc = documents[documentHash];
        doc.hash = documentHash;
        doc.signer = msg.sender;
        doc.timestamp = block.timestamp;
        doc.isPublic = isPublic;

        for (uint i = 0; i < allowedRoles.length; i++) {
            doc.allowedRoles[allowedRoles[i]] = true;
            emit DocumentAccessGranted(documentHash, allowedRoles[i]);
        }

        emit DocumentSigned(documentHash, msg.sender, block.timestamp);
    }

    function verifyDocument(bytes32 documentHash, bytes memory signature) public view returns (bool) {
        Document storage doc = documents[documentHash];
        require(doc.hash == documentHash, "Document not found");

        address recoveredSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(documentHash), signature);
        return recoveredSigner == doc.signer;
    }

    function canAccessDocument(bytes32 documentHash, address user) public view returns (bool) {
        Document storage doc = documents[documentHash];
        if (doc.isPublic) {
            return true;
        }
        if (hasRole(MASTER_ROLE, user) || hasRole(AUDITOR_ROLE, user)) {
            return true;
        }
        if (doc.allowedRoles[BONDHOLDER_ROLE] && hasRole(BONDHOLDER_ROLE, user)) {
            return true;
        }
        return false;
    }
}
