// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC3643 is IERC20 {
    function forcedTransfer(address from, address to, uint256 amount) external returns (bool);
    function isIssuable() external view returns (bool);
    // Add other ERC3643 specific functions as needed
}
