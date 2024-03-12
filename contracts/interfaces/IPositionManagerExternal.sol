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
        address rebalancer;
        /// @param data - optional bytes parameter for custom user defined data
        bytes data;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `borrowAndRebalance` function.
    struct CreateLoanBorrowAndRebalanceExternallyParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev owner of NFT created by PositionManager. Owns loan through PositionManager
        address to;
        /// @dev reference id of loan observer to track loan
        uint16 refId;
        /// @dev amounts of requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint256[] amounts;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev Ratio to rebalance collateral to
        address rebalancer;
        /// @dev Ratio to rebalance collateral to
        bytes data;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens`. Slippage protection
        uint256[] minBorrowed;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
    }

    /// @dev Struct parameters for `repayLiquidity` function. Repaying liquidity
    struct RebalanceExternallyAndRepayLiquidityParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose liquidity debt will be paid
        uint256 tokenId;
        /// @dev liquidity debt to pay
        uint256 liquidity;
        /// @dev amounts of requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint128[] amounts;
        /// @dev Ratio to rebalance collateral to
        address rebalancer;
        /// @dev Ratio to rebalance collateral to
        bytes data;
        /// @dev collateralId - index of collateral token + 1
        uint256 collateralId;
        /// @dev to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint256[] minRepaid;
    }

    /// @dev Struct parameters for `createLoanBorrowAndRebalance` function.
    struct BorrowAndRebalanceExternallyParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev CFMM LP tokens requesting to borrow during external rebalancing. Must be returned at function call end
        address rebalancer;
        /// @param data - optional bytes parameter for custom user defined data
        bytes data;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan
        uint256[] amounts;
        /// @dev amounts of reserve tokens requesting to withdraw from a loan's collateral
        uint128[] withdraw;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens` (borrowing). Slippage protection
        uint256[] minBorrowed;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        uint128[] minCollateral;
        /// @dev max borrowed liquidity
        uint256 maxBorrowed;
    }

    /// @dev Re-balance loan collateral tokens by swapping one for another using an external source
    /// @param params - struct containing params to identify a GammaPool and loan with information to re-balance its collateral
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateralExternally(RebalanceCollateralExternallyParams calldata params) external returns(uint256 loanLiquidity, uint128[] memory tokensHeld);

    /// @notice Aggregate create loan, increase collateral, borrow collateral, and re-balance collateral externally into one transaction
    /// @dev Only create loan must be performed, the other transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokenId - tokenId of newly created loan
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function createLoanBorrowAndRebalanceExternally(CreateLoanBorrowAndRebalanceExternallyParams calldata params) external returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);

    /// @dev Repay liquidity debt from GammaPool rebalancing collateral externally to pay the debt in the proper ratio
    /// @param params - struct containing params to identify a GammaPool and loan to pay its liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function rebalanceExternallyAndRepayLiquidity(RebalanceExternallyAndRepayLiquidityParams calldata params) external returns (uint256 liquidityPaid, uint256[] memory amounts);

    /// @notice Aggregate increase collateral, borrow collateral, re-balance collateral externally, and decrease collateral into one transaction
    /// @dev All transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function borrowAndRebalanceExternally(BorrowAndRebalanceExternallyParams calldata params) external returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);
}
