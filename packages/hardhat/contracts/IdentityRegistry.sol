// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IdentityRegistry {
    struct Identity {
        address onchainID;
        uint256 nationality;
        uint256 country;
    }

    mapping(address => Identity) public identities;

    function addIdentity(address _user, address _onchainID, uint256 _nationality, uint256 _country) public {
        identities[_user] = Identity(_onchainID, _nationality, _country);
    }

    function getIdentity(address _user) public view returns (Identity memory) {
        return identities[_user];
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IIdentityRegistry.sol";
import "./ClaimTopicsRegistry.sol";
import "./TrustedIssuersRegistry.sol";
import "./IdentityRegistryStorage.sol";

contract IdentityRegistry is IIdentityRegistry, AccessControl {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SHARIA_ADVISOR_ROLE = keccak256("SHARIA_ADVISOR_ROLE");

    ClaimTopicsRegistry public claimTopicsRegistry;
    TrustedIssuersRegistry public trustedIssuersRegistry;
    IdentityRegistryStorage public identityStorage;

    constructor(
        address _claimTopicsRegistry,
        address _trustedIssuersRegistry,
        address _identityStorage
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        claimTopicsRegistry = ClaimTopicsRegistry(_claimTopicsRegistry);
        trustedIssuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        identityStorage = IdentityRegistryStorage(_identityStorage);
    }

    function assignRole(address account, bytes32 role) external onlyRole(MASTER_ROLE) {
        grantRole(role, account);
    }

    function revokeRole(address account, bytes32 role) external onlyRole(MASTER_ROLE) {
        revo

    function registerIdentity(
        address _identity,
        uint16 _country,
        uint256[] memory _investorCategory
    ) external onlyRole(AGENT_ROLE) {
        identityStorage.addIdentityToStorage(_identity, _country, _investorCategory);
    }

    function updateIdentity(
        address _identity,
        uint16 _country,
        uint256[] memory _investorCategory
    ) external onlyRole(AGENT_ROLE) {
        identityStorage.modifyStoredIdentity(_identity, _country, _investorCategory);
    }

    function deleteIdentity(address _identity) external onlyRole(AGENT_ROLE) {
        identityStorage.removeIdentityFromStorage(_identity);
    }

    function isVerified(address _identity) external view override returns (bool) {
        if (!identityStorage.contains(_identity)) {
            return false;
        }
        return hasAllRequiredClaims(_identity);
    }

    function hasAllRequiredClaims(address _identity) public view returns (bool) {
        uint256[] memory requiredClaimTopics = claimTopicsRegistry.getClaimTopics();
        if (requiredClaimTopics.length == 0) {
            return true;
        }
        uint256 claimTopicsCount = requiredClaimTopics.length;
        address identityAddress = identityStorage.storedIdentity(_identity);
        for (uint256 i = 0; i < claimTopicsCount; i++) {
            if (!_hasClaimTopic(identityAddress, requiredClaimTopics[i])) {
                return false;
            }
        }
        return true;
    }

    function _hasClaimTopic(address _identity, uint256 _claimTopic) internal view returns (bool) {
        uint256 trustedIssuersCount = trustedIssuersRegistry.getTrustedIssuersCount();
        for (uint256 i = 0; i < trustedIssuersCount; i++) {
            address trustedIssuer = trustedIssuersRegistry.getTrustedIssuer(i);
            if (_checkClaimValidity(_identity, _claimTopic, trustedIssuer)) {
                return true;
            }
        }
        return false;
    }

    function _checkClaimValidity(
        address _identity,
        uint256 _claimTopic,
        address _issuer
    ) internal view returns (bool) {
        // Get the claim from the identity contract
        (uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri) = IIdentity(_identity).getClaim(_claimTopic, _issuer);
        
        // Verify the claim signature
        bytes32 messageHash = keccak256(abi.encodePacked(_identity, topic, data));
        require(issuer == _issuer, "Invalid issuer");
        require(topic == _claimTopic, "Invalid claim topic");
        require(isValidSignature(messageHash, signature, _issuer), "Invalid signature");
        
        // Check if the claim has expired
        uint256 expirationTime = abi.decode(data, (uint256));
        require(block.timestamp <= expirationTime, "Claim has expired");
        
        // Verify the issuer is still trusted
        require(trustedIssuersRegistry.isTrustedIssuer(_issuer), "Issuer is not trusted");
        
        return true;
    }

    function isValidSignature(bytes32 _messageHash, bytes memory _signature, address _signer) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(ethSignedMessageHash, v, r, s) == _signer;
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) v += 27;
    }

    // Implement other functions as needed
}
