// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompliance {
    function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool);
    function transferred(address _from, address _to, uint256 _amount) external;
    function created(address _to, uint256 _amount) external;
    function destroyed(address _from, uint256 _amount) external;
    // Add other compliance specific functions as needed
}
