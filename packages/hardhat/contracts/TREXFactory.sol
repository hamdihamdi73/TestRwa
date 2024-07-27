// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SukukBond.sol";

contract TREXFactory {
    event SukukBondCreated(address sukukBondAddress);

    function createSukukBond(string memory uri, address compliance) public returns (address) {
        SukukBond sukukBond = new SukukBond(uri, compliance);
        emit SukukBondCreated(address(sukukBond));
        return address(sukukBond);
    }
}