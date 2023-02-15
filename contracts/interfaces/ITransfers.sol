// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@gammaswap/v1-core/contracts/interfaces/IRefunds.sol";
import "@gammaswap/v1-core/contracts/interfaces/periphery/ISendTokensCallback.sol";

/// @title Interface for Transfers abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface used to send tokens and clear tokens and Ether from a contract
interface ITransfers is ISendTokensCallback, IRefunds {

    /// @return WETH - address of Wrapped Ethereum contract
    function WETH() external view returns (address);

    /// @dev Refund ETH balance to caller
    function refundETH() external payable;

    /// @dev Unwrap Wrapped ETH in contract and send ETH to recipient `to`
    /// @param minAmt - threshold balance of WETH which must be crossed before ETH can be refunded
    /// @param to - destination address where ETH will be sent to
    function unwrapWETH(uint256 minAmt, address to) external payable;
}