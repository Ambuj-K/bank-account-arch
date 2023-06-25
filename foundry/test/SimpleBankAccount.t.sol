// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author Add3 <ambuj@add3.io>

import "forge-std/Test.sol";
import "../src/implementation/SimpleBankAccount.sol";
import "../src/vault/Vault.sol";
import "../src/controller/Controller.sol";
import "../src/controller/IController.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../token/ERC20.sol";

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
    ERC20 public token;
    ERC20 public token1;
    Vault public VaultObj;
    Controller public ControllerObj;

    function setUp() public {
        token =new ERC20("token",
        "tk");
        token1 =new ERC20("token1",
        "tk1");
        token.mint(address(this), 1000000 * 1e18); // deploy and mint to the test contract i.e. "owner wallet"
        token1.mint(address(this), 1000000 * 1e18); 
        SimpleBankAccountObj = new SimpleBankAccount();
        SimpleBankAccountObj.setTimestamp(365 days );
        SimpleBankAccountObj.setInterestPercent(10 );

        VaultObj = new Vault(address(token), address(this));

        ControllerObj = new Controller(address(VaultObj),address(this));
        // add rewardtokens by the owner wallet i.e. test contract
        token.approve(address(this), address(VaultObj), 500 ether);
        VaultObj.setControllerAddress(address(ControllerObj) );
        VaultObj.depositToVault(500 ether);
        VaultObj.getAvailableTokens();
        // register product on controller
        ControllerObj.registerProduct(address(SimpleBankAccountObj), 500 ether, IController.productTypes.SIMPLE_ACCOUNT);
    }

    function testCreateDepositWithdrawClaim() public {
        // create campaign via addr
        address addr = 0x1234567890123456789012345678901234567890;
        token.transfer(address(addr), 1000 ether);
        emit log_uint(token.balanceOf(address(addr)));
        cheats.startPrank(address(addr));
        // approval from 1st acc for contract transfer
        token.approve(address(addr), address(SimpleBankAccountObj), 30 ether);
        // addr contributes tokens
        SimpleBankAccountObj.depositTokens(30 ether);
        cheats.stopPrank();
        // use 2nd address to contribute
        address addr1 = 0x1234567890123456789012345678901234567892;
        token.transfer(address(addr1), 1000 ether);
        emit log_uint(token.balanceOf(address(addr1)));
        cheats.startPrank(address(addr1));
        // approval from 2nd acc for contract transfer
        token.approve(address(addr1), address(SimpleBankAccountObj), 20 ether);
        // addr 1 contribute tokens
        SimpleBankAccountObj.depositTokens(20 ether);
        cheats.stopPrank();
        emit log_uint(token.balanceOf(address(addr1)));
        assertEq(token.balanceOf(address(addr1)), 980 ether);
        // use 3rd address to contribute
        address addr2 = 0x1234567890123456789012345678901234567893;
        token.transfer(address(addr2), 1000 ether);
        emit log_uint(token.balanceOf(address(addr2)));
        cheats.startPrank(address(addr2));
        // approval from 3rd acc for contract transfer
        token.approve(address(addr2), address(SimpleBankAccountObj), 20 ether);
        // addr 2 contribute
        SimpleBankAccountObj.depositTokens(20 ether);
        cheats.stopPrank();
        assertEq(token.balanceOf(address(addr2)), 980 ether);
        cheats.startPrank(address(addr1));
        cheats.warp(365 days+1 minutes);
        // withdraw 10 ether from  via addr1
        SimpleBankAccountObj.withdrawTokens(10 ether);
        cheats.stopPrank();
        emit log_uint(token.balanceOf(address(addr2)));
        assertEq(token.balanceOf(address(addr1)), 990 ether);
        // check balance to 30
        cheats.warp(92 days);
        assertEq(token.balanceOf(address(SimpleBankAccountObj)), 1030 ether);
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
