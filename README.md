# Setup

```shell
cd foundry
npm i @openzeppelin/contracts-upgradeable
npm i @openzeppelin/contracts
```

# Description

The Architecture Elements:

SimpleBankAccount: Allows a user to deposit, earn simple interest (without lockin) for the time period tokens are held in the account contract, and withdraw the supported tokens.

Controller: Acts as the controlling authority for deployment of multiple product/account variants i.e. SimpleBankAccount, CompoundBankAccount, CompoundLockingPeriodAccount, and handles interest earned transfer from Vault.

Vault: Holds the interest rate to be transferred from bank to the Account contract.

Adding testcases, enhanced.

# Running testcases 

Unit Testcases For SimpleBankAccount Product

```shell
# Simple Bank Account
forge test --match-path test/SimpleBankAccount.t.sol -vvvvv
