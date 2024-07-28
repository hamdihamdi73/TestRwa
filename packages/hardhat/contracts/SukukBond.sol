// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Roles.sol";
import "./ModularCompliance.sol";

contract SukukBond is ERC1155, Ownable, AccessControl {
    enum CouponPeriod { MONTHLY, WEEKLY, TRIMESTRIAL, SEMI_ANNUAL, ANNUAL }

    struct BondDetails {
        string name;
        string symbol;
        uint256 totalSupply;
        CouponPeriod couponPeriod;
        uint256 maturity;
        string currency;
        string esgLabel;
        string category;
        address onchainID;
        uint256 firstCouponTime;
        uint256 purchasePeriodEnd;
    }

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    mapping(uint256 => BondDetails) public bondDetails;
    mapping(uint256 => uint256) public bondsPurchased;
    ModularCompliance public compliance;

    event UpdatedTokenInformation(
        uint256 indexed id,
        string name,
        string symbol,
        uint256 totalSupply,
        CouponPeriod couponPeriod,
        uint256 maturity,
        string currency,
        string esgLabel,
        string category,
        address onchainID,
        uint256 firstCouponTime,
        uint256 purchasePeriodEnd
    );
    event IdentityRegistryAdded(address indexed identityRegistry);
    event ComplianceAdded(address indexed compliance);

    constructor(string memory uri, address _compliance) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        compliance = ModularCompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    function createBond(
        uint256 id,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        CouponPeriod couponPeriod,
        uint256 maturity,
        string memory currency,
        string memory esgLabel,
        string memory category,
        address onchainID,
        uint256 firstCouponTime,
        uint256 purchasePeriodDuration,
        bytes memory data
    ) public onlyRole(ISSUER_ROLE) {
        require(firstCouponTime > block.timestamp, "First coupon time must be in the future");
        uint256 purchasePeriodEnd = block.timestamp + purchasePeriodDuration;
        require(purchasePeriodEnd < firstCouponTime, "Purchase period must end before first coupon");

        bondDetails[id] = BondDetails(
            name,
            symbol,
            totalSupply,
            couponPeriod,
            maturity,
            currency,
            esgLabel,
            category,
            onchainID,
            firstCouponTime,
            purchasePeriodEnd
        );
        _mint(msg.sender, id, totalSupply, data);
        emit UpdatedTokenInformation(
            id,
            name,
            symbol,
            totalSupply,
            couponPeriod,
            maturity,
            currency,
            esgLabel,
            category,
            onchainID,
            firstCouponTime,
            purchasePeriodEnd
        );
    }

    function getBondDetails(uint256 id) public view returns (BondDetails memory) {
        return bondDetails[id];
    }

    function addAttributes(uint256 id, string memory newCategory) public onlyRole(MASTER_ROLE) {
        bondDetails[id].category = newCategory;
    }

    function transferBond(
        address to,
        uint256 id,
        uint256 amount,
        uint256 requiredNationality,
        uint256 requiredCountry
    ) public {
        require(compliance.isCompliant(to, requiredNationality, requiredCountry), "Compliance check failed");
        safeTransferFrom(msg.sender, to, id, amount, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // Override supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function purchaseBond(uint256 id, uint256 amount) public onlyRole(INVESTOR_ROLE) {
        BondDetails storage bond = bondDetails[id];
        require(block.timestamp <= bond.purchasePeriodEnd, "Purchase period has ended");
        require(bondsPurchased[id] + amount <= bond.totalSupply, "Exceeds available bonds");

        bondsPurchased[id] += amount;
        safeTransferFrom(owner(), msg.sender, id, amount, "");
    }

    function releaseBonds(uint256 id) public onlyRole(ISSUER_ROLE) {
        BondDetails storage bond = bondDetails[id];
        require(block.timestamp > bond.purchasePeriodEnd, "Purchase period has not ended");
        require(bondsPurchased[id] == bond.totalSupply, "Not all bonds were purchased");

        // Additional logic for releasing bonds to investors
        // This could involve transferring funds, setting up coupon payments, etc.
    }

    function returnFunds(uint256 id) public onlyRole(ISSUER_ROLE) {
        BondDetails storage bond = bondDetails[id];
        require(block.timestamp > bond.purchasePeriodEnd, "Purchase period has not ended");
        require(bondsPurchased[id] < bond.totalSupply, "All bonds were purchased");

        // Logic to return funds to investors
        // This could involve refunding purchases, burning unsold tokens, etc.
    }
}
