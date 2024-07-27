// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IdentityRegistry.sol";

contract ModularCompliance {
    IdentityRegistry identityRegistry;

    constructor(address _identityRegistry) {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }

    function isCompliant(address _user, uint256 _requiredNationality, uint256 _requiredCountry) public view returns (bool) {
        IdentityRegistry.Identity memory identity = identityRegistry.getIdentity(_user);
        return identity.nationality == _requiredNationality && identity.country == _requiredCountry;
    }
}