// SPDX-License-Identifier: GPL-3.0

// How it works. Deposit made by user is held in the contract. When user deposits more, balance is updated in contract.
// assuming that you get a fixed reward for your time held
// when user withdraws interest is sent from vault + contract balance lessened.
// 100% of interest are transferred every withdraw is the easiest way to handle the interest + account_val seperation

/// @author: Ambuj
/// @title SimpleBankAccount

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../controller/IController.sol";
import "./ISimpleBankAccount.sol";

contract SimpleBankAccount is ISimpleBankAccount {

    // boolean to prevent reentrancy
    bool internal locked;

    // Contract owner
    address public _owner;

    // Library usage
    using SafeERC20 for IERC20;

    // Timestamp related variables
    uint256 public initialTimestamp; // since
    uint256 public interestPercent; // new
    bool public interestSet; // new create getter

    // Token amount variables
    // to track withdrawn tokens
    mapping(address => mapping(address=> uint256)) public alreadyWithdrawn;
    // current balance state
    mapping(address => mapping(address=> uint256)) public balances;
    // time of deposit held
    mapping(address => mapping(address=> uint256)) private depositTime;
    mapping(address => uint256) private interestPerSecond;

    address private controllerAddress;
    IController private icontroller;

    // ERC20 contract address mapping public viewing
    mapping(string => address) public tokenSupported;

    // Events
    event tokensDeposited(address from, uint256 amount);
    event interestClaimed(address who, uint256 amount);
    event TokensWithDrawn(address to, uint256 amount);

    error Error_Only_Owner();
    error Error_Address_Zero();
    error Error_depositToken_Not_Enough_Deposit_Tokens();
    error Error_depositToken_Not_Enough_Vault_Interest_For_Deposit();
    error Error_withdrawToken_Insufficient_Token();
    error Error_No_Reentrancy();
    error Error_Interest_Already_Set();
    error Error_Interest_Not_Set();
    error Error_Token_Name_Addr_Count_Mismatch();
    error Error__rotateInterest_Controller_Get_interests();
    error Error__rotateInterest_Controller_Address_Not_Set();
    error Error_depositToken_Controller_Address_Not_Set();


    modifier onlyOwner{if (msg.sender!=_owner){ revert Error_Only_Owner(); } _;}

    ///@dev Deploys contract and links the ERC20 token which we are staking, also sets owner as _owner
   constructor(address[] memory _erc20_contract_addresses, string[] memory _erc20_contract_names, address __owner) {
        // Set contract owner
        _owner = __owner;

        if (_erc20_contract_addresses.length != _erc20_contract_names.length) {
            revert Error_Token_Name_Addr_Count_Mismatch();    
        }
        for (uint256 i = 0; i < _erc20_contract_addresses.length; i++) {
            if (_erc20_contract_addresses[i] == address(0)){ 
                revert Error_Address_Zero(); 
            }
            tokenSupported[_erc20_contract_names[i]] = _erc20_contract_addresses[i];
        }

        // Initialize the reentrancy variable to not locked
        locked = false;
   }

    /*//////////////////////////////////////////////////////////////
                        FUNCTIONS/COMPONENTS
    //////////////////////////////////////////////////////////////*/

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        if (locked){ revert Error_No_Reentrancy(); }
        locked = true;
        _;
        locked = false; }

    // Modifier - new
    /**
    * @dev Throws if percentage interest not set.
    */
    modifier interestIsSet() {
        if (!interestSet) { revert Error_Interest_Not_Set(); }
        _; }

    // Modifier - new
    /**
    * @dev Throws if percentage interest already set.
    */
    modifier interestNotSet() {
        if (interestSet) { revert Error_Interest_Already_Set(); }
        _; }


    /// @dev Sets the controller address for usage
    /// Also, the controller constructor makes it not feasible to be inherited
    function setControllerAddress(address _controllerAddress) public onlyOwner {

        controllerAddress = _controllerAddress;

        icontroller = IController(controllerAddress); }


    function setInterestPercent(uint256 _interestRate) public onlyOwner interestNotSet  {
        interestSet = true;
        interestPercent = _interestRate; }


    // interest Calculation Logic Virtual Override!
    function _wps(address token_addr) internal  returns (bool) {
        uint256 temp = balances[msg.sender][token_addr];
        // Let's calculate the maximum amount which can be earned per annum (start with mul calculation first so we avoid values lower than one)
        uint256 maxInterestEarned_unshifted = temp*(interestPercent);
        // Lets calculate the amount to a accuracy of 0.01%
        uint256 maxInterestEarned = maxInterestEarned_unshifted/(10000);
        // Now that we have the proper max amount of interest, let's calculate amount per second
        uint256 weiPerSecond = maxInterestEarned/(31536000);
        interestPerSecond[msg.sender] = weiPerSecond;
        return true; }

    // Deposit Logic Virtual Override option
    function _rotateInterest(address token_addr) internal returns (bool) {
        if(balances[msg.sender][token_addr] == 0){
            return true; //done
        }else{
            // i want to add any yield earned to balance
            // now
            uint256 withdraw = block.timestamp;

            // calculate staking time
            uint256 timeDeposited = withdraw-(depositTime[msg.sender][token_addr]);

            // calculte interest
            uint256 interests = timeDeposited*(interestPerSecond[msg.sender]);

            // update balances
            balances[msg.sender][token_addr] = balances[msg.sender][token_addr]+(interests);

            // then transfer 
            if (controllerAddress == address(0)) { revert Error__rotateInterest_Controller_Address_Not_Set(); }

            if(!icontroller.claimReward(address(this), interests, token_addr)){ revert Error__rotateInterest_Controller_Get_interests(); }
            
            emit interestClaimed(msg.sender, interests);
            return true; } }

    // TimeLogic virtual override
    function _timeLogic(address token_addr) internal  { depositTime[msg.sender][token_addr] = block.timestamp; }

    function _depositLogic(uint256 amt, address token_addr) internal {
        // Transfer tokens to smart contract 
        balances[msg.sender][token_addr] = balances[msg.sender][token_addr]+(amt);
        IERC20(token_addr).safeTransferFrom(msg.sender, address(this), amt); }

    function _withdrawLogic(uint256 amount, address token_addr) internal {
        alreadyWithdrawn[msg.sender][token_addr] = alreadyWithdrawn[msg.sender][token_addr]+(amount);

        if(balances[msg.sender][token_addr] == amount){ balances[msg.sender][token_addr] = 0; }

        else { balances[msg.sender][token_addr] = balances[msg.sender][token_addr]-(amount); }

        IERC20(token_addr).safeTransfer(msg.sender, amount); }


    /// @dev Allows the token owner to deposit
    /// @param amount to allocate to recipient.
    /// @param token_addr the address token deposited
    function depositTokens(uint256 amount, address token_addr) public noReentrant {
        if(amount > IERC20(token_addr).balanceOf(msg.sender)){  revert Error_depositToken_Not_Enough_Deposit_Tokens(); }

        if (controllerAddress == address(0)) { revert Error_depositToken_Controller_Address_Not_Set(); }

        _rotateInterest(token_addr);

        if(!icontroller.checkValidDeposit(amount, address(this), IERC20(token_addr).balanceOf(address(this)), interestPercent, token_addr)){ revert Error_depositToken_Not_Enough_Vault_Interest_For_Deposit(); }
        
        _depositLogic(amount, token_addr);
        
        _timeLogic(token_addr);
        _wps(token_addr);

        // emit 
        emit tokensDeposited(msg.sender, amount); }

    /// @dev Allows user to withdraw tokens 
    /// @param amount - the amount to unlock (in wei)
    /// @param token_addr - the address token withdrawn
    function withdrawTokens(uint256 amount, address token_addr) public noReentrant {
        if(balances[msg.sender][token_addr] < amount) { revert Error_withdrawToken_Insufficient_Token(); }
        
        _rotateInterest(token_addr); // changes on deposited amount
        
        _withdrawLogic(amount, token_addr);
        
        _timeLogic(token_addr);
        _wps(token_addr);

        emit TokensWithDrawn(msg.sender, amount); }

    function withdrawAll(address token_addr)  public {
        
        _rotateInterest(token_addr); // changes on deposited amount
        _wps(token_addr);
        _timeLogic(token_addr);

        uint256 amount = balances[msg.sender][token_addr];
        _withdrawLogic(amount, token_addr);
        emit TokensWithDrawn(msg.sender, amount); }

}
