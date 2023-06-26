// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author Add3 <ambuj@add3.io>

import "forge-std/Test.sol";
import "../src/implementation/SimpleBankAccount.sol";
import "../src/vault/Vault.sol";
import "../src/controller/Controller.sol";
import "../src/controller/IController.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/tokens/InterMediateToken.sol";

interface CheatCodes {
    function startPrank(address) external;
    function stopPrank() external;
    function expectEmit(bool, bool, bool, bool) external;
    function warp(uint256) external;
    function roll(uint256) external;
    function prank(address) external;
}

// testcase covers Regular Static/LP Static Staking

contract SimpleBankAccountTest is DSTest {
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    SimpleBankAccount public SimpleBankAccountObj;
    MyToken public token;
    MyToken public token1;
    Vault public VaultObj;
    Controller public ControllerObj;
    address[] tokenAddressArray;
    string[] tokenNameArray;

    function setUp() public {
        token =new MyToken("US Dollar",
        "USD");
        token1 =new MyToken("Euro",
        "EUR");
        tokenAddressArray = [address(token), address(token1)];
        tokenNameArray = ["USD", "Eur"];
        token.mint(address(this), 1000000 * 1e18); 
        // deploy and mint to the test contract i.e. "owner wallet"
        token1.mint(address(this), 1000000 * 1e18); 

        SimpleBankAccountObj = new SimpleBankAccount(tokenAddressArray,tokenNameArray, address(this));
        SimpleBankAccountObj.setInterestPercent(1000); //10% bps points 1000

        VaultObj = new Vault(address(this));

        ControllerObj = new Controller(address(VaultObj),address(this));
        SimpleBankAccountObj.setControllerAddress(address(ControllerObj) );
        // add rewardtokens by the owner wallet i.e. test contract
        token.approve(address(VaultObj), 500 ether);
        token1.approve(address(VaultObj), 500 ether);
        VaultObj.setControllerAddress(address(ControllerObj));
        VaultObj.depositToVault(500 ether, address(token));
        VaultObj.getAvailableTokens(address(token));
        VaultObj.depositToVault(500 ether, address(token1));
        VaultObj.getAvailableTokens(address(token1));
        // register product on controller
        ControllerObj.registerProduct(address(SimpleBankAccountObj), 500 ether, IController.productTypes.SIMPLE_ACCOUNT, tokenAddressArray);
    }

    function testCreateDepositWithdrawClaim() public {
        // create campaign via addr
        address addr = 0x1234567890123456789012345678901234567890;
        token.transfer(address(addr), 1000 ether);
        token1.transfer(address(addr), 1000 ether);
        emit log_uint(token.balanceOf(address(addr)));
        cheats.startPrank(address(addr));
        // approval from 1st acc for contract transfer
        token.approve(address(SimpleBankAccountObj), 30 ether);
        token1.approve(address(SimpleBankAccountObj), 30 ether);
        // addr contributes tokens
        SimpleBankAccountObj.depositTokens(30 ether, address(token));
        SimpleBankAccountObj.depositTokens(30 ether, address(token1));
        cheats.stopPrank();
        // use 2nd address to contribute
        address addr1 = 0x1234567890123456789012345678901234567892;
        token.transfer(address(addr1), 1000 ether);
        token1.transfer(address(addr1), 1000 ether);
        emit log_uint(token.balanceOf(address(addr1)));
        cheats.startPrank(address(addr1));
        // approval from 2nd acc for contract transfer
        token.approve(address(SimpleBankAccountObj), 20 ether);
        token1.approve(address(SimpleBankAccountObj), 20 ether);
        // addr 1 contribute tokens
        SimpleBankAccountObj.depositTokens(20 ether, address(token));
        SimpleBankAccountObj.depositTokens(20 ether, address(token1));
        cheats.stopPrank();
        emit log_uint(token.balanceOf(address(addr1)));
        assertEq(token.balanceOf(address(addr1)), 980 ether);
        // use 3rd address to contribute
        address addr2 = 0x1234567890123456789012345678901234567893;
        token.transfer(address(addr2), 1000 ether);
        token1.transfer(address(addr2), 1000 ether);
        emit log_uint(token.balanceOf(address(addr2)));
        cheats.startPrank(address(addr2));
        // approval from 3rd acc for contract transfer
        token.approve(address(SimpleBankAccountObj), 20 ether);
        token1.approve(address(SimpleBankAccountObj), 20 ether);
        // addr 2 contribute
        SimpleBankAccountObj.depositTokens(20 ether, address(token));
        SimpleBankAccountObj.depositTokens(20 ether, address(token1));
        cheats.stopPrank();
        assertEq(token.balanceOf(address(addr2)), 980 ether);
        cheats.startPrank(address(addr1));
        cheats.warp(365 days);
        // withdraw 20 ether from  via addr1
        emit log_uint(SimpleBankAccountObj.getBalance(address(addr1),address(token1)));

        // 10 percent of 20 tokens 2 tokens interst 22 withdrawn
        SimpleBankAccountObj.withdrawTokens(22 ether, address(token)); 
        SimpleBankAccountObj.withdrawTokens(22 ether, address(token1));
        cheats.stopPrank();
        emit log_uint(token.balanceOf(address(addr2)));
        assertEq(token.balanceOf(address(addr1)), 1002 ether);
        assertEq(token1.balanceOf(address(addr1)), 1002 ether);
        emit log_uint(SimpleBankAccountObj.getBalance(address(addr1),address(token1)));
        // check balance to 30
        cheats.warp(10 days);
        // assertEq(token.balanceOf(address(SimpleBankAccountObj)), 1030 ether);
    }

    // create campaign
    // function testLaunchCampaign() public {
    //     address addr = 0x1234567890123456789012345678901234567890;
    //     token.transfer(address(addr), 1000 ether);
    //     emit log_uint(token.balanceOf(address(addr)));
    //     cheats.startPrank(address(addr));
    //     SimpleBankAccountObj.launchCampaign(100 ether, uint32(block.timestamp + 1 days), uint32(block.timestamp + 91 days));
    //     cheats.stopPrank();
    //     emit log_address(SimpleBankAccountObj.getCampaign(0).creator);
    //     assertEq(SimpleBankAccountObj.getCampaign(0).creator,addr);
    // }

}
