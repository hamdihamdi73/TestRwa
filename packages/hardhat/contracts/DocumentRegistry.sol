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
    bytes32 public constant SHARIA_COMPLIANCE_ROLE = keccak256("SHARIA_COMPLIANCE_ROLE");
    bytes32 public constant ESG_LABEL_ROLE = keccak256("ESG_LABEL_ROLE");

    struct Document {
        bytes32 hash;
        address signer;
        uint256 timestamp;
        bool isPublic;
        string ipfsCID;
        mapping(bytes32 => bool) allowedRoles;
        mapping(bytes32 => Certificate) certificates; // mapping of certificate types to certificates
    }

    struct Certificate {
        bool exists;
        address issuer;
        uint256 timestamp;
        string details; // details or IPFS CID pointing to certificate details
    }

    mapping(bytes32 => Document) public documents;
    IPFSUtils public ipfsUtils;

    event DocumentSigned(bytes32 indexed documentHash, address indexed signer, uint256 timestamp, string ipfsCID);
    event DocumentAccessGranted(bytes32 indexed documentHash, bytes32 indexed role);
    event CertificateIssued(bytes32 indexed documentHash, bytes32 indexed certificateType, address indexed issuer, string details);

    constructor(address _ipfsUtils) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        ipfsUtils = IPFSUtils(_ipfsUtils);
    }

    function signDocument(bytes32 documentHash, bool isPublic, bytes32[] memory allowedRoles, string memory ipfsCID) external {
        require(
            hasRole(ISSUER_ROLE, msg.sender) || hasRole(AUDITOR_ROLE, msg.sender) || hasRole(MASTER_ROLE, msg.sender),
            "Not authorized to sign documents"
        );
        
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

    function issueCertificate(bytes32 documentHash, string memory ipfsCID, bytes32 certificateType, string memory details) external {
        require(
            (certificateType == keccak256("SHARIA_COMPLIANCE") && hasRole(SHARIA_COMPLIANCE_ROLE, msg.sender)) ||
            (certificateType == keccak256("ESG_LABEL") && hasRole(ESG_LABEL_ROLE, msg.sender)),
            "Not authorized to issue this certificate"
        );
        
        bytes32 ipfsHash = ipfsUtils.getIPFSHash(documentHash, ipfsCID);
        Document storage doc = documents[ipfsHash];
        require(doc.hash == documentHash, "Document not found");

        doc.certificates[certificateType] = Certificate({
            exists: true,
            issuer: msg.sender,
            timestamp: block.timestamp,
            details: details
        });

        emit CertificateIssued(ipfsHash, certificateType, msg.sender, details);
    }

    function getCertificate(bytes32 documentHash, string memory ipfsCID, bytes32 certificateType) public view returns (Certificate memory) {
        bytes32 ipfsHash = ipfsUtils.getIPFSHash(documentHash, ipfsCID);
        Document storage doc = documents[ipfsHash];
        require(doc.hash == documentHash, "Document not found");

        Certificate memory cert = doc.certificates[certificateType];
        require(cert.exists, "Certificate not found");
        
        return cert;
    }
}
