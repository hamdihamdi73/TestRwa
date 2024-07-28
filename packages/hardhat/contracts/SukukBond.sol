// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC3643.sol";
import "./IdentityRegistry.sol";
import "./Compliance.sol";
import "./DocumentRegistry.sol";

contract SukukBond is ERC20, AccessControl, IERC3643 {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant BONDHOLDER_ROLE = keccak256("BONDHOLDER_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant SHARIA_ADVISOR_ROLE = keccak256("SHARIA_ADVISOR_ROLE");

    IdentityRegistry public identityRegistry;
    Compliance public compliance;
    DocumentRegistry public documentRegistry;

    struct SukukDetails {
        uint256 maturity;
        uint256 profitRate;
        uint256 profitDistributionPeriod;
        uint256 faceValue;
        string currency;
        string assetType;
        string sukukStructure;
        bool isShariahCompliant;
    }

    SukukDetails public sukukDetails;
    uint256 public lastProfitDistributionTimestamp;
    uint256 public nextProfitAmount;
    uint256 public profitValidationDeadline;
    bool public isProfitValidated;
    mapping(address => uint256) public unclaimedProfits;

    address public underlyingAssetAddress;
    uint256 public totalInvestedAmount;

    constructor(
        string memory name,
        string memory symbol,
        address _identityRegistry,
        address _compliance,
        address _documentRegistry
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
        _setupRole(AUDITOR_ROLE, msg.sender);
        _setupRole(MASTER_ROLE, msg.sender);
        _setupRole(SHARIA_ADVISOR_ROLE, msg.sender);
        identityRegistry = IdentityRegistry(_identityRegistry);
        compliance = Compliance(_compliance);
        documentRegistry = DocumentRegistry(_documentRegistry);
    }

    function setSukukDetails(
        uint256 _maturity,
        uint256 _profitRate,
        uint256 _profitDistributionPeriod,
        uint256 _faceValue,
        string memory _currency,
        string memory _assetType,
        string memory _sukukStructure,
        address _underlyingAssetAddress
    ) external onlyRole(ISSUER_ROLE) {
        sukukDetails = SukukDetails(
            _maturity,
            _profitRate,
            _profitDistributionPeriod,
            _faceValue,
            _currency,
            _assetType,
            _sukukStructure,
            false // isShariahCompliant, to be set by Shariah advisor
        );
        lastProfitDistributionTimestamp = block.timestamp;
        underlyingAssetAddress = _underlyingAssetAddress;
    }

    function approveShariah() external onlyRole(SHARIA_ADVISOR_ROLE) {
        sukukDetails.isShariahCompliant = true;
        emit ShariahApproved();
    }

    function revokeShariah() external onlyRole(SHARIA_ADVISOR_ROLE) {
        sukukDetails.isShariahCompliant = false;
        emit ShariahRevoked();
    }

    event ShariahApproved();
    event ShariahRevoked();

    function setProfitAmount(uint256 _amount) external onlyRole(ISSUER_ROLE) {
        require(block.timestamp >= lastProfitDistributionTimestamp + sukukDetails.profitDistributionPeriod, "Profit distribution period not elapsed");
        require(block.timestamp < sukukDetails.maturity, "Sukuk has matured");
        require(sukukDetails.isShariahCompliant, "Sukuk is not Shariah compliant");
        nextProfitAmount = _amount;
        profitValidationDeadline = block.timestamp + 1 weeks;
        isProfitValidated = false;
        emit ProfitAmountSet(_amount);
    }

    function validateProfitAmount() external onlyRole(AUDITOR_ROLE) {
        require(block.timestamp <= profitValidationDeadline, "Validation period has passed");
        isProfitValidated = true;
        emit ProfitAmountValidated(nextProfitAmount);
    }

    function distributeProfits() external {
        require(hasRole(MASTER_ROLE, msg.sender) || hasRole(AUDITOR_ROLE, msg.sender), "Caller is not authorized");
        require(isProfitValidated, "Profit amount not validated");
        require(block.timestamp < sukukDetails.maturity, "Sukuk has matured");
        require(sukukDetails.isShariahCompliant, "Sukuk is not Shariah compliant");

        uint256 totalSupply = totalSupply();
        uint256 profitPerToken = nextProfitAmount * 1e18 / totalSupply;

        for (uint256 i = 0; i < totalSupply; i++) {
            address holder = ownerOf(i);
            uint256 profitAmount = (balanceOf(holder) * profitPerToken) / 1e18;
            unclaimedProfits[holder] += profitAmount;
        }

        lastProfitDistributionTimestamp = block.timestamp;
        emit ProfitsDistributed(nextProfitAmount);
    }

    function claimProfit() external {
        uint256 amount = unclaimedProfits[msg.sender];
        require(amount > 0, "No unclaimed profits");
        unclaimedProfits[msg.sender] = 0;
        require(IERC20(underlyingAssetAddress).transfer(msg.sender, amount), "Profit transfer failed");
        emit ProfitClaimed(msg.sender, amount);
    }

    event ProfitAmountSet(uint256 amount);
    event ProfitAmountValidated(uint256 amount);
    event ProfitsDistributed(uint256 totalAmount);
    event ProfitClaimed(address indexed holder, uint256 amount);

    function mint(address to, uint256 amount) external onlyRole(ISSUER_ROLE) {
        require(identityRegistry.isVerified(to), "Recipient is not verified");
        require(compliance.canTransfer(address(0), to, amount), "Transfer not compliant");
        _mint(to, amount);
        compliance.created(to, amount);
        _setupRole(BONDHOLDER_ROLE, to);
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
        if (balanceOf(msg.sender) == 0) {
            revokeRole(BONDHOLDER_ROLE, msg.sender);
        }
    }

    function forcedBurn(address account, uint256 amount) external onlyRole(AGENT_ROLE) {
        require(compliance.canTransfer(account, address(0), amount), "Forced burn not compliant");
        _burn(account, amount);
        compliance.destroyed(account, amount);
    }

    function signDocument(bytes32 documentHash, bool isPublic, bytes32[] memory allowedRoles, string memory ipfsCID) external onlyRole(ISSUER_ROLE) {
        documentRegistry.signDocument(documentHash, isPublic, allowedRoles, ipfsCID);
    }

    function verifyDocument(bytes32 documentHash, string memory ipfsCID, bytes memory signature) external view returns (bool) {
        return documentRegistry.verifyDocument(documentHash, ipfsCID, signature);
    }

    function canAccessDocument(bytes32 documentHash, string memory ipfsCID, address user) external view returns (bool) {
        return documentRegistry.canAccessDocument(documentHash, ipfsCID, user);
    }

    function getDocumentIPFSCID(bytes32 documentHash, string memory ipfsCID) external view returns (string memory) {
        return documentRegistry.getDocumentIPFSCID(documentHash, ipfsCID);
    }

    function mint(address to, uint256 amount) external override onlyRole(ISSUER_ROLE) {
        require(identityRegistry.isVerified(to), "Recipient is not verified");
        require(compliance.canTransfer(address(0), to, amount), "Transfer not compliant");
        _mint(to, amount);
        compliance.created(to, amount);
        _setupRole(BONDHOLDER_ROLE, to);
    }
}
    function invest(uint256 amount) external {
        require(sukukDetails.isShariahCompliant, "Sukuk is not Shariah compliant");
        require(block.timestamp < sukukDetails.maturity, "Sukuk has matured");
        require(IERC20(underlyingAssetAddress).transferFrom(msg.sender, address(this), amount), "Investment transfer failed");
        uint256 tokensToMint = (amount * 1e18) / sukukDetails.faceValue;
        _mint(msg.sender, tokensToMint);
        totalInvestedAmount += amount;
        emit Invested(msg.sender, amount, tokensToMint);
    }

    function redeem(uint256 tokenAmount) external {
        require(block.timestamp >= sukukDetails.maturity, "Sukuk has not matured yet");
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        uint256 redeemAmount = (tokenAmount * sukukDetails.faceValue) / 1e18;
        _burn(msg.sender, tokenAmount);
        require(IERC20(underlyingAssetAddress).transfer(msg.sender, redeemAmount), "Redemption transfer failed");
        emit Redeemed(msg.sender, tokenAmount, redeemAmount);
    }

    event Invested(address indexed investor, uint256 amount, uint256 tokensReceived);
    event Redeemed(address indexed investor, uint256 tokenAmount, uint256 amountRedeemed);
