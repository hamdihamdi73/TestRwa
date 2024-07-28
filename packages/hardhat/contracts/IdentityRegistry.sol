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

    ClaimTopicsRegistry public claimTopicsRegistry;
    TrustedIssuersRegistry public trustedIssuersRegistry;
    IdentityRegistryStorage public identityStorage;

    constructor(
        address _claimTopicsRegistry,
        address _trustedIssuersRegistry,
        address _identityStorage
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        claimTopicsRegistry = ClaimTopicsRegistry(_claimTopicsRegistry);
        trustedIssuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        identityStorage = IdentityRegistryStorage(_identityStorage);
    }

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
        // Implement claim validity check logic
        // This would typically involve verifying the claim signature and expiration
        return true; // Placeholder
    }

    // Implement other functions as needed
}
