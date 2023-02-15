// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Wrapped Ether interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Used to interact with Wrapped Ether contract
/// @dev Only defines functions we
interface IWETH is IERC20 {
    /// @dev Emitted when Ether is deposited into Wrapped Ether contract to issue Wrapped Ether
    /// @param to - receiver of wrapped ether
    /// @param amount - amount of wrapped ether issued to receiver
    event Deposit(address indexed to, uint amount);

    /// @dev Emitted when Ether is withdrawn from Wrapped Ether contract by burning Wrapped Ether
    /// @param from - receiver of ether
    /// @param amount - amount of ether sent to `from`
    event Withdrawal(address indexed from, uint amount);

    /// @dev Deposit ether to issue Wrapped Ether
    function deposit() external payable;

    /// @dev Withdraw ether by burning Wrapped Ether
    function withdraw(uint256) external;
}
