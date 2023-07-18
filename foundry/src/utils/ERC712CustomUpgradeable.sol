// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @author @ambuj-k
/// @title ERC712CustomUpgradeable
/// This abstract class can be inherited and used by all contracts using the EIP712 functions

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "../privilegedaddressregistry/IPrivilegedAddressRegistry.sol";

abstract contract ERC712CustomUpgradeable is EIP712Upgradeable {

    using ECDSAUpgradeable for bytes32;

    mapping(address => uint256) public nonces;

    IPrivilegedAddressRegistry privilegedAddressObj;

    error Error_Unauthorized_Signature();
    error Error_Unauthorized_Deadline_Expired();

    function processSignatureVerification(bytes memory encoded_params, bytes memory signature, uint256 deadline, address verificationAddr) internal{ 

        if (msg.sender != verificationAddr){
            if(block.timestamp > deadline){ revert Error_Unauthorized_Deadline_Expired();}

            address signer = ECDSAUpgradeable.recover(_hashTypedDataV4(keccak256(encoded_params)), signature);
            nonces[verificationAddr]++;
            if (verificationAddr != signer){ revert Error_Unauthorized_Signature();} } 
        }
}