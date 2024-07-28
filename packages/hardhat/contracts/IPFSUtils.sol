// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IPFSUtils {
    function getIPFSHash(bytes32 documentHash, string memory ipfsCID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(documentHash, ipfsCID));
    }
}
