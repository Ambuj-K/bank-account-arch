// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

// Author Add3 dvncan

interface ISimpleBankAccount{

    // function setTimestamp(uint256 _lockup_period) external;

    // function setInterestPercent(uint256 _interestRate) external;

    //function _wps() internal  returns (bool);

    //function _rotateReward();

    //function _timeLogic();

    //function _lockupLogic();

    //function _depositLogic(uint256 amt);

    //function _withdrawLogic(uint256 amount);

    function depositTokens(uint256, address) external;

    function withdrawTokens(uint256, address) external;

    function rotateInterest(address) external;

    function withdrawAll(address) external;

    // function transferAccidentallyLockedTokens(IERC20 token, uint256 amount) external;
}

