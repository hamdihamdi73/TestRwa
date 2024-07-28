// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IPFSUtils.sol";

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
        string ipfsCID;
        mapping(bytes32 => bool) allowedRoles;
    }

    mapping(bytes32 => Document) public documents;
    IPFSUtils public ipfsUtils;

    event DocumentSigned(bytes32 indexed documentHash, address indexed signer, uint256 timestamp, string ipfsCID);
    event DocumentAccessGranted(bytes32 indexed documentHash, bytes32 indexed role);

    constructor(address _ipfsUtils) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        ipfsUtils = IPFSUtils(_ipfsUtils);
    }

    function signDocument(bytes32 documentHash, bool isPublic, bytes32[] memory allowedRoles, string memory ipfsCID) external {
        require(hasRole(ISSUER_ROLE, msg.sender) || hasRole(AUDITOR_ROLE, msg.sender) || hasRole(MASTER_ROLE, msg.sender), "Not authorized to sign documents");
        
        bytes32 ipfsHash = ipfsUtils.getIPFSHash(documentHash, ipfsCID);
        Document storage doc = documents[ipfsHash];
        doc.hash = documentHash;
        doc.signer = msg.sender;
        doc.timestamp = block.timestamp;
        doc.isPublic = isPublic;
        doc.ipfsCID = ipfsCID;

        for (uint i = 0; i < allowedRoles.length; i++) {
            doc.allowedRoles[allowedRoles[i]] = true;
            emit DocumentAccessGranted(ipfsHash, allowedRoles[i]);
        }

        emit DocumentSigned(ipfsHash, msg.sender, block.timestamp, ipfsCID);
    }

    function verifyDocument(bytes32 documentHash, string memory ipfsCID, bytes memory signature) public view returns (bool) {
        bytes32 ipfsHash = ipfsUtils.getIPFSHash(documentHash, ipfsCID);
        Document storage doc = documents[ipfsHash];
        require(doc.hash == documentHash, "Document not found");

        address recoveredSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(documentHash), signature);
        return recoveredSigner == doc.signer;
    }

    function canAccessDocument(bytes32 documentHash, string memory ipfsCID, address user) public view returns (bool) {
        bytes32 ipfsHash = ipfsUtils.getIPFSHash(documentHash, ipfsCID);
        Document storage doc = documents[ipfsHash];
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

    function getDocumentIPFSCID(bytes32 documentHash, string memory ipfsCID) public view returns (string memory) {
        bytes32 ipfsHash = ipfsUtils.getIPFSHash(documentHash, ipfsCID);
        return documents[ipfsHash].ipfsCID;
    }
}
