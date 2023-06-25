// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

/// @title IVault Interface
/// @author Ambuj
interface IVault {
    function depositToVault(uint256, address) external;

    function withdrawFromVault(address, uint256, address) external;

    function getAvailableTokens(address) external view returns(uint256);

}
