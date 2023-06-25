// SPDX-License-Identifier: GPL-3.0

/// @author Ambuj
/// @title Controller contract
/// @author - Ambuj 

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IController.sol";
import "../vault/IVault.sol";

contract Controller is IController, ReentrancyGuard{

    struct product{
        productTypes productType;
        bool active;
        uint256 availableReward;
        address[] tokenList;
    }

    mapping(address => product) products;

    address private vaultAddress;
    address private clientAdmin;
    address private stakingAdapter;

    //uint256 private totalRewardsAllProducts;

    error Error_Not_Owner();
    error Error_Not_Owner_Or_Adapter();
    error Error_Reward_Amount_Lesser_Than_Vault_Bal();
    error Error_Staking_Adapter_Not_Set();
    error Error_Unauthorized_Signature();
    error Error_Unauthorized_Deadline_Expired();

    modifier onlyClientOrAdapter{
        if (stakingAdapter == address(0)) { revert Error_Staking_Adapter_Not_Set();}
        if (msg.sender != clientAdmin && msg.sender != stakingAdapter) { revert Error_Not_Owner_Or_Adapter(); }
        _; }

    modifier onlyClient{
        if (msg.sender != clientAdmin) { revert Error_Not_Owner(); }
        _; }

    constructor(address _vaultAddress, address _clientAdmin){
        vaultAddress = _vaultAddress;
        clientAdmin = _clientAdmin;
    }


    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // keep in mind common module for regular,LP staking
    // Checks if a user deposit is doable and the vault has enough tokens to reward that user
    // @param amount of tokens being deposited
    // @param address of the product being used
    // @param balance of the product being used
    // @param interest of the product being used
    function checkValidDeposit(uint256 amount, address addr, uint256 contractBalance, uint256 interestPercentage, address token_addr) external view onlyClientOrAdapter returns (bool){
        // check vault reward amount is greater than set reward amount
        if (products[addr].productType == (productTypes.SIMPLE_ACCOUNT)) {
        // at any point of time given deposit withdraw patterns the vault must have the APY of the contract balance
        if (((contractBalance+amount)*interestPercentage)/10000  <= IVault(vaultAddress).getAvailableTokens(token_addr)){ return true; }
        return false; } 
        return true;  }

    // Fills the vault with tokens to later use for the registered accounts
    // @param tokenAddress token being deposited into the vault 
    // @param amount of tokens being deposited into the vault as rewards
    // @modifiers onlyClientOrAdapter, nonReentrant
    function depositAssetToVault(address contractaddr,uint256 amount, address token_addr) external onlyClientOrAdapter nonReentrant{ 
        IVault(vaultAddress).depositToVault(amount, token_addr); }

    // Function to claim a reward for a user
    // @param rewardRate so we dont over subscribe 
    // @modifiers onlyClient, nonReentrant
    function claimReward(address productAddress, uint256 claimAmount, address token_addr) external onlyClientOrAdapter nonReentrant{
        products[productAddress].availableReward -= claimAmount;

        IVault(vaultAddress).withdrawFromVault(productAddress, claimAmount, token_addr); 
    }

    // Registers new product supported by the controller/vault 
    // @param contractAddress so that we can add to spend list
    // @param rewardAmount so we cant over-subscribe
    // @param productTypes so we know what kind if product is being registered
    // @modifiers onlyClient, enoughRewards, nonReentrant
    function registerProduct(address productAddress, uint256 rewardAmount, productTypes productType, address[] calldata _tokenList) external onlyClient nonReentrant{
        // add interest needed for all tokens before registering
        for (uint256 i = 0; i < _tokenList.length; i++) {
        if (IVault(vaultAddress).getAvailableTokens(_tokenList[i]) < rewardAmount)
        { 
            revert Error_Reward_Amount_Lesser_Than_Vault_Bal(); 
        }
        }

        products[productAddress].productType = productType;
        products[productAddress].availableReward = rewardAmount;
        products[productAddress].active = true;
        products[productAddress].tokenList = _tokenList;

    }

    // Removes the product from the controller (users will be told to withdraw or exit funds.)
    // @param Address of the deployed product
    // @modifiers onlyClient, nonReentrant
    function removeProduct(address productAddress) external onlyClient nonReentrant{
        //upon deregistering admin wallet will recieve the leftover available rewards from vault
        for (uint256 i = 0; i < products[productAddress].tokenList.length; i++) {
            IVault(vaultAddress).withdrawFromVault(clientAdmin, products[productAddress].availableReward, products[productAddress].tokenList[i]);
        }

        products[productAddress].active = false;
        products[productAddress].availableReward = 0; 
        // products[productAddress].tokenList =;
    }

    // Add token support
    // @param Address of the new token
    // @modifiers onlyClient, nonReentrant
    function addTokenInProduct(address productAddress,address new_token) external onlyClient nonReentrant{
        // products[productAddress].tokenList.append(new_token);
    }

}