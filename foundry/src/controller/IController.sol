// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.11;

/// @title IController Interface
/// @author Ambuj
interface IController {

    enum productTypes{
        SIMPLE_ACCOUNT,
        COMPOUND_ACCOUNT
    }

    // Checks if a user deposit is doable and the vault has enough tokens to reward that user
    // @param amount of tokens being deposited
    // @param address of the product being used
    function checkValidDeposit(uint256, address, uint256, uint256, address) external returns (bool);

    // Fills the vault with tokens to later use for the registered products
    // @param tokenAddress token being deposited into the vault 
    // @param amount of tokens being deposited into the vault as rewards
    function depositAssetToVault(address,uint256,address) external;

    // Function to claim a reward for a user
    // @param productAddress to reduce the tokens available 
    // @param claimer the user claiming the reward 
    // @param claimAmount totalTokens to be claimed from the vault 
    // @modifiers onlyAdd3, nonReentrant
    function claimReward(address, uint256, address) external returns (bool);

    // Registers new product supported by the controller/vault 
    // @param contractAddress so that we can add to spend list
    // @param rewardAmount so we cant over-subscribe
    // @param productTypes so we know what kind if product is being registered
    // @modifiers onlyAdd3, enoughRewards, nonReentrant
    function registerProduct(address, uint256, productTypes, address[] calldata) external;

    // Removes the product from the controller (users will be told to withdraw or exit funds before doing this.)
    // @param Address of the deployed product
    function removeProduct(address) external;

    // Helps edit product, add token support
    // @param Address of the deployed product
    // @param Amount to increment the reward
    function addTokenInProduct(address, address) external;
    

}

