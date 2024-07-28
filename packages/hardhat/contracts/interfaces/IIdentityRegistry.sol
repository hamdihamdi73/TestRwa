// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIdentityRegistry {
    function isVerified(address _identity) external view returns (bool);
    // Add other identity registry specific functions as needed
}
