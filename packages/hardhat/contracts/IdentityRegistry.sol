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
}