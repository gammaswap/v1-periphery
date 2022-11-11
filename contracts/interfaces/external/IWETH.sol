// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event Deposit(address indexed to, uint amount);
    event Withdrawal(address indexed from, uint amount);

    // Deposit ether to get wrapped ether
    function deposit() external payable;

    // Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}
