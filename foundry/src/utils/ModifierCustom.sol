// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @author @ambuj-k
/// @title ModifierCustom
/// This abstract class is inherited and used by all contracts which need to limit resetting of the state addresses/variables, which should be set once only.

abstract contract ModifierCustom {

    enum customTypes{
        ADAPTER_SET,
        ADAPTER_NOT_SET,
        VAULT_SET,
        VAULT_NOT_SET,
        CONTROLLER_SET,
        CONTROLLER_NOT_SET,
        STATIC_STAKING_INTEREST_SET,
        STATIC_STAKING_INTERST_NOT_SET,
        STATIC_STAKING_TIMETAMP_SET,
        STATIC_STAKING_TIMETAMP_NOT_SET,
        FEE_STRATEGY_SET,
        PRODUCT_REGISTERED,
        PRODUCT_NOT_REGISTERED
    }

    error Error_Adapter_Not_Set();
    error Error_Adapter_Set();
    error Error_Vault_Not_Set();
    error Error_Vault_Set();
    error Error_Controller_Not_Set();
    error Error_Controller_Set();
    error Error_Interest_Set();
    error Error_Interest_Not_Set();
    error Error_Timestamp_Set();
    error Error_Timestamp_Not_Set();
    error Error_Fee_Strategy_Set();
    error Error_Product_Registered();
    error Error_Product_Not_Registered();

    modifier customModifier(bool valueVar, customTypes customType) { 
        
        if(customType == customTypes.ADAPTER_NOT_SET){if (!valueVar) { revert Error_Adapter_Not_Set(); } }
        
        else if(customType == customTypes.ADAPTER_SET){if (valueVar) { revert Error_Adapter_Set(); } }

        else if(customType == customTypes.VAULT_NOT_SET){if (!valueVar) { revert Error_Vault_Not_Set(); } }

        else if(customType == customTypes.VAULT_SET){if (valueVar) { revert Error_Vault_Set(); } }

        else if(customType == customTypes.CONTROLLER_NOT_SET){if (!valueVar) { revert Error_Controller_Not_Set(); } }

        else if(customType == customTypes.CONTROLLER_SET){if (valueVar) { revert Error_Controller_Set(); } }

        else if(customType == customTypes.STATIC_STAKING_INTEREST_SET){if (valueVar) { revert Error_Interest_Set(); } }

        else if(customType == customTypes.STATIC_STAKING_INTERST_NOT_SET){if (!valueVar) { revert Error_Interest_Not_Set(); } }

        else if(customType == customTypes.STATIC_STAKING_TIMETAMP_SET){if (valueVar) { revert Error_Timestamp_Set(); } }

        else if(customType == customTypes.STATIC_STAKING_TIMETAMP_NOT_SET){if (!valueVar) { revert Error_Timestamp_Not_Set(); } }

        else if(customType == customTypes.FEE_STRATEGY_SET){if (valueVar) { revert Error_Fee_Strategy_Set(); } }

        else if(customType == customTypes.PRODUCT_REGISTERED){if (valueVar) { revert Error_Product_Registered(); } }

        else if(customType == customTypes.PRODUCT_NOT_REGISTERED){if (valueVar) { revert Error_Product_Not_Registered(); } }

        _;
    }

}