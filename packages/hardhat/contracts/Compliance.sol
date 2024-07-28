// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ICompliance.sol";
import "./SukukBond.sol";
import "./IdentityRegistry.sol";

contract Compliance is ICompliance, AccessControl {
    SukukBond public sukukBond;
    IdentityRegistry public identityRegistry;

    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");

    mapping(address => bool) public frozen;
    uint256 public maxHolderCount;
    uint256 public currentHolderCount;

    struct TransferRestriction {
        uint256 minAmount;
        uint256 maxAmount;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => TransferRestriction) public transferRestrictions;

    constructor(address _identityRegistry) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        identityRegistry = IdentityRegistry(_identityRegistry);
    }

    function setSukukBond(address _sukukBond) external onlyRole(MASTER_ROLE) {
        sukukBond = SukukBond(_sukukBond);
    }

    function canTransfer(address _from, address _to, uint256 _amount) external view override returns (bool) {
        if (frozen[_from] || frozen[_to]) {
            return false;
        }
        if (_from == address(0) && currentHolderCount >= maxHolderCount) {
            return false;
        }
        if (_to != address(0) && sukukBond.balanceOf(_to) == 0) {
            if (currentHolderCount >= maxHolderCount) {
                return false;
            }
        }
    
        TransferRestriction memory restriction = transferRestrictions[_from];
        if (restriction.startTime != 0) {
            if (block.timestamp < restriction.startTime || block.timestamp > restriction.endTime) {
                return false;
            }
            if (_amount < restriction.minAmount || _amount > restriction.maxAmount) {
                return false;
            }
        }
    
        if (_from != address(0) && !identityRegistry.hasRole(identityRegistry.INVESTOR_ROLE(), _from)) {
            return false;
        }
    
        return true;
    }

    function setTransferRestriction(address _address, uint256 _minAmount, uint256 _maxAmount, uint256 _startTime, uint256 _endTime) external onlyRole(AGENT_ROLE) {
        transferRestrictions[_address] = TransferRestriction(_minAmount, _maxAmount, _startTime, _endTime);
    }

    function transferred(address _from, address _to, uint256 _amount) external override onlyRole(AGENT_ROLE) {
        if (_from == address(0)) {
            currentHolderCount++;
        }
        if (sukukBond.balanceOf(_to) == 0) {
            currentHolderCount++;
        }
        if (sukukBond.balanceOf(_from) == _amount) {
            currentHolderCount--;
        }
    }

    function created(address _to, uint256 _amount) external override onlyRole(AGENT_ROLE) {
        if (sukukBond.balanceOf(_to) == 0) {
            currentHolderCount++;
        }
    }

    function destroyed(address _from, uint256 _amount) external override onlyRole(AGENT_ROLE) {
        if (sukukBond.balanceOf(_from) == _amount) {
            currentHolderCount--;
        }
    }

    function setMaxHolderCount(uint256 _maxHolderCount) external onlyRole(MASTER_ROLE) {
        maxHolderCount = _maxHolderCount;
    }

    function freezeAddress(address _address) external onlyRole(AGENT_ROLE) {
        frozen[_address] = true;
    }

    function unfreezeAddress(address _address) external onlyRole(AGENT_ROLE) {
        frozen[_address] = false;
    }
}
