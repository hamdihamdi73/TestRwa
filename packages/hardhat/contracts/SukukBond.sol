// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Roles.sol";
import "./ModularCompliance.sol";

contract SukukBond is ERC1155, Ownable, AccessControl {
    struct BondDetails {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 couponPeriod;
        uint256 maturity;
        string currency;
        string esgLabel;
        string category;
        address onchainID;
    }

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");

    mapping(uint256 => BondDetails) public bondDetails;
    ModularCompliance public compliance;

    event UpdatedTokenInformation(
        uint256 indexed id,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 couponPeriod,
        uint256 maturity,
        string currency,
        string esgLabel,
        string category,
        address onchainID
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
        uint256 couponPeriod,
        uint256 maturity,
        string memory currency,
        string memory esgLabel,
        string memory category,
        address onchainID,
        bytes memory data
    ) public onlyRole(ISSUER_ROLE) {
        bondDetails[id] = BondDetails(
            name,
            symbol,
            totalSupply,
            couponPeriod,
            maturity,
            currency,
            esgLabel,
            category,
            onchainID
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
            onchainID
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
}