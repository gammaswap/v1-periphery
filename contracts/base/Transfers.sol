// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@gammaswap/v1-core/contracts/libraries/GammaSwapLibrary.sol";
import "../interfaces/ITransfers.sol";
import "../interfaces/external/IWETH.sol";

/// @title Transfers abstract contract implementation of ITransfers
/// @author Daniel D. Alcarraz
/// @notice Clears tokens and Ether from PositionManager and simplifies token transfer functions
/// @dev PositionManager is not supposed to hold any tokens or Ether
abstract contract Transfers is ITransfers {

    error NotWETH();
    error NotEnoughWETH();
    error NotEnoughTokens();
    error NotGammaPool();

    /// @dev See {ITransfers-WETH}
    address public immutable override WETH;

    /// @dev Initialize the contract by setting `WETH`
    constructor(address _WETH) {
        WETH = _WETH;
    }

    /// @dev Do not accept any Ether unless it comes from Wrapped Ether (WETH) contract
    receive() external payable {
        if(msg.sender != WETH) {
          revert NotWETH();
        }
    }

    /// @dev See {ITransfers-unwrapWETH}
    function unwrapWETH(uint256 minAmt, address to) public payable override {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));
        if(wethBal < minAmt) {
            revert NotEnoughWETH();
        }

        if (wethBal > 0) {
            IWETH(WETH).withdraw(wethBal);
            GammaSwapLibrary.safeTransferETH(to, wethBal);
        }
    }

    /// @dev See {ITransfers-refundETH}
    function refundETH() external payable override {
        if (address(this).balance > 0) GammaSwapLibrary.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @dev See {ITransfers-clearToken}
    function clearToken(address token, address to, uint256 minAmt) public virtual override {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if(tokenBal < minAmt) {
            revert NotEnoughTokens();
        }

        if (tokenBal > 0) GammaSwapLibrary.safeTransfer(IERC20(token), to, tokenBal);
    }

    /// @dev Used to abstract token transfer functions into one function call
    /// @param token - ERC20 token to transfer
    /// @param sender - address sending the token
    /// @param to - recipient of token `amount` from sender
    /// @param amount - quantity of `token` that will be sent to recipient `to`
    function send(address token, address sender, address to, uint256 amount) internal {
        if (token == WETH && address(this).balance >= amount) {
            IWETH(WETH).deposit{value: amount}(); // wrap only what is needed
            GammaSwapLibrary.safeTransfer(IERC20(WETH), to, amount);
        } else if (sender == address(this)) {
            // send with tokens already in the contract
            GammaSwapLibrary.safeTransfer(IERC20(token), to, amount);
        } else {
            // pull transfer
            GammaSwapLibrary.safeTransferFrom(IERC20(token), sender, to, amount);
        }
    }

    /// @dev Used to transfer multiple tokens in one function call
    /// @param tokens - ERC20 tokens to transfer
    /// @param sender - address sending the token
    /// @param to - recipient of token `amount` from sender
    /// @param amounts - quantity of `token` that will be sent to recipient `to`
    function sendTokens(address[] memory tokens, address sender, address to, uint256[] calldata amounts) internal {
        uint256 len = tokens.length;
        for (uint256 i; i < len;) {
            if (amounts[i] > 0 ) send(tokens[i], sender, to, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Retrieves GammaPool address using cfmm address and protocolId
    /// @param cfmm - address of CFMM of GammaPool whose address we want to calculate
    /// @param protocolId - identifier of GammaPool implementation for the `cfmm`
    /// @return pool - address of GammaPool
    function getGammaPoolAddress(address cfmm, uint16 protocolId) internal virtual view returns(address);

    /// @dev See {ISendTokensCallback-sendTokensCallback}.
    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external virtual override {
        SendTokensCallbackData memory decoded = abi.decode(data, (SendTokensCallbackData));

        // Revert if msg.sender is not GammaPool for CFMM and protocolId
        if(msg.sender != getGammaPoolAddress(decoded.cfmm, decoded.protocolId)) {
            revert NotGammaPool();
        }

        // Transfer tokens from decoded.payer to payee
        sendTokens(tokens, decoded.payer, payee, amounts);
    }
}