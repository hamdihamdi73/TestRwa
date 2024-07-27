// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClaimTopicsRegistry {
    mapping(uint256 => bool) public claimTopics;

    function addClaimTopic(uint256 _claimTopic) public {
        claimTopics[_claimTopic] = true;
    }

    function removeClaimTopic(uint256 _claimTopic) public {
        claimTopics[_claimTopic] = false;
    }

    function isClaimTopic(uint256 _claimTopic) public view returns (bool) {
        return claimTopics[_claimTopic];
    }
}