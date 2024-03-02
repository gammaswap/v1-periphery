// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPositionManager.sol";

/// @title Interface for PositionManagerExternal
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Defines external functions and events emitted by PositionManagerExternal
/// @dev Interface also defines all GammaPool events through inheritance of IGammaPool and IGammaPoolEvents
interface IPositionManagerExternal is IPositionManager {

    /// @dev Emitted when re-balancing a loan's collateral amounts (swapping one collateral token for another) using an external contract
    /// @param pool - loan's pool address
    /// @param tokenId - id identifying loan in pool
    /// @param loanLiquidity - liquidity borrowed in invariant terms
    /// @param tokensHeld - new loan collateral amounts
    event RebalanceCollateralExternally(address indexed pool, uint256 tokenId, uint256 loanLiquidity, uint128[] tokensHeld);

    /// @dev Struct parameters for `rebalanceCollateralExternally` function.
    struct RebalanceCollateralExternallyParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        uint128[] amounts;
        /// @dev CFMM LP tokens requesting to borrow during external rebalancing. Must be returned at function call end
        uint256 lpTokens;
        /// @dev address of contract that will rebalance collateral. This address must return collateral back to GammaPool
        address to;
        /// @param data - optional bytes parameter for custom user defined data
        bytes data;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Re-balance loan collateral tokens by swapping one for another using an external source
    /// @param params - struct containing params to identify a GammaPool and loan with information to re-balance its collateral
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateralExternally(RebalanceCollateralExternallyParams calldata params) external returns(uint256 loanLiquidity, uint128[] memory tokensHeld);

}
