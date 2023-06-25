// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVault.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
contract Vault is IVault{
    using SafeTransferLib for IERC20;

    error Only_Admin_Callable();
    error Only_Controller_Callable();
    error Controller_Address_Not_Set();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw( address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    
    address private clientAdmin;
    address private controller;

    modifier onlyClient{ 
        if(msg.sender != clientAdmin) { 
            revert Only_Admin_Callable();  
        } 
        _; 
    }

    modifier onlyController{ if(msg.sender != controller) {
        revert Only_Controller_Callable();
        } 
        _; 
    }

    constructor( address admin ){ 
        clientAdmin = admin; 
    }


    /*//////////////////////////////////////////////////////////////
                    SET CCONTROLLER ADDRESS(Post Deployment)
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets the controller address for usage
    function setControllerAddress(address _controller, uint256 deadline, bytes memory signature) public onlyClient {

        controller = _controller; 
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function depositToVault(uint256 amount, address token_addr) public onlyClient {

        if (controller == address(0)) { revert Controller_Address_Not_Set(); }

        IERC20(token_addr).transferFrom(msg.sender, address(this), amount); 
    
    }

    // used to withdraw Tokens from the vault, through the controller
    function withdrawFromVault(address claimer, uint256 claimAmount, address token_addr) public onlyController{
        if (controller == address(0)) { revert Controller_Address_Not_Set(); }

        IERC20(token_addr).transfer(claimer, claimAmount); 
    }

    function getAvailableTokens(address token_addr) public view returns(uint256){ 
        return IERC20(token_addr).totalSupply(); 
    }

}