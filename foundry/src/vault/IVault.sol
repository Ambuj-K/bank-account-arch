// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Add3 protocol.

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.11;

/// @title IVault Interface
/// @author Add3 <juan@add3.io>
/// @dev modified by Add3 <ambuj@add3.io>
interface IVault {
    function depositToVault(uint256, address) external;

    function withdrawFromVault(address, uint256, address) external;

    function getAvailableTokens(address) external view returns(uint256);

}
