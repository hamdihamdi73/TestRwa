// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC3643.sol";
import "./IdentityRegistry.sol";
import "./Compliance.sol";

contract SukukBond is ERC20, AccessControl, IERC3643 {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    IdentityRegistry public identityRegistry;
    Compliance public compliance;

    struct BondDetails {
        uint256 maturity;
        uint256 couponRate;
        uint256 couponPeriod;
        uint256 faceValue;
        string currency;
        string esgLabel;
        string category;
    }

    BondDetails public bondDetails;
    uint256 public lastCouponTimestamp;

    constructor(
        string memory name,
        string memory symbol,
        address _identityRegistry,
        address _compliance
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
        identityRegistry = IdentityRegistry(_identityRegistry);
        compliance = Compliance(_compliance);
    }

    function setBondDetails(
        uint256 _maturity,
        uint256 _couponRate,
        uint256 _couponPeriod,
        uint256 _faceValue,
        string memory _currency,
        string memory _esgLabel,
        string memory _category
    ) external onlyRole(ISSUER_ROLE) {
        bondDetails = BondDetails(
            _maturity,
            _couponRate,
            _couponPeriod,
            _faceValue,
            _currency,
            _esgLabel,
            _category
        );
        lastCouponTimestamp = block.timestamp;
    }

    function calculateCoupon(address holder) public view returns (uint256) {
        uint256 balance = balanceOf(holder);
        uint256 timeSinceLastCoupon = block.timestamp - lastCouponTimestamp;
        uint256 periodsElapsed = timeSinceLastCoupon / bondDetails.couponPeriod;
        
        if (periodsElapsed == 0) {
            return 0;
        }

        uint256 couponAmount = (balance * bondDetails.couponRate * periodsElapsed) / (100 * 365 days / bondDetails.couponPeriod);
        return couponAmount;
    }

    function distributeCoupons() external onlyRole(ISSUER_ROLE) {
        require(block.timestamp >= lastCouponTimestamp + bondDetails.couponPeriod, "Coupon period not elapsed");

        uint256 totalSupply = totalSupply();
        uint256 totalCouponAmount = 0;

        for (uint256 i = 0; i < totalSupply; i++) {
            address holder = ownerOf(i);
            uint256 couponAmount = calculateCoupon(holder);
            if (couponAmount > 0) {
                _mint(holder, couponAmount);
                totalCouponAmount += couponAmount;
            }
        }

        lastCouponTimestamp = block.timestamp;
        emit CouponsDistributed(totalCouponAmount);
    }

    event CouponsDistributed(uint256 totalAmount);

    function mint(address to, uint256 amount) external onlyRole(ISSUER_ROLE) {
        require(identityRegistry.isVerified(to), "Recipient is not verified");
        require(compliance.canTransfer(address(0), to, amount), "Transfer not compliant");
        _mint(to, amount);
        compliance.created(to, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(identityRegistry.isVerified(to), "Recipient is not verified");
        require(compliance.canTransfer(msg.sender, to, amount), "Transfer not compliant");
        bool success = super.transfer(to, amount);
        if (success) {
            compliance.transferred(msg.sender, to, amount);
        }
        return success;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(identityRegistry.isVerified(to), "Recipient is not verified");
        require(compliance.canTransfer(from, to, amount), "Transfer not compliant");
        bool success = super.transferFrom(from, to, amount);
        if (success) {
            compliance.transferred(from, to, amount);
        }
        return success;
    }

    function setIdentityRegistry(address _identityRegistry) external onlyRole(ISSUER_ROLE) {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }

    function setCompliance(address _compliance) external onlyRole(ISSUER_ROLE) {
        compliance = Compliance(_compliance);
    }

    function forcedTransfer(address from, address to, uint256 amount) external onlyRole(AGENT_ROLE) returns (bool) {
        require(identityRegistry.isVerified(to), "Recipient is not verified");
        _transfer(from, to, amount);
        compliance.transferred(from, to, amount);
        return true;
    }

    function isIssuable() external view override returns (bool) {
        return hasRole(ISSUER_ROLE, msg.sender);
    }

    // Implement other IERC3643 functions as needed

    function burn(uint256 amount) public virtual {
        require(compliance.canTransfer(msg.sender, address(0), amount), "Burn not compliant");
        _burn(msg.sender, amount);
        compliance.destroyed(msg.sender, amount);
    }

    function forcedBurn(address account, uint256 amount) external onlyRole(AGENT_ROLE) {
        require(compliance.canTransfer(account, address(0), amount), "Forced burn not compliant");
        _burn(account, amount);
        compliance.destroyed(account, amount);
    }
}
