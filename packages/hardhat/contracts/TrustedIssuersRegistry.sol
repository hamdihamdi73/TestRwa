// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrustedIssuersRegistry {
    mapping(address => bool) public trustedIssuers;

    function addTrustedIssuer(address _issuer) public {
        trustedIssuers[_issuer] = true;
    }

    function removeTrustedIssuer(address _issuer) public {
        trustedIssuers[_issuer] = false;
    }

    function isTrustedIssuer(address _issuer) public view returns (bool) {
        return trustedIssuers[_issuer];
    }
}