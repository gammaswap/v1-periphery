// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolEvents.sol";
import "./ITransfers.sol";

/// @title Interface for PositionManager
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Defines external functions and events emitted by PositionManager
/// @dev Interface also defines all GammaPool events through inheritance of IGammaPoolEvents
interface IPositionManager is IGammaPoolEvents, ITransfers {
    /// @dev Emitted when depositing CFMM LP tokens as liquidity in a pool
    /// @param pool - address of pool minting GS LP tokens
    /// @param shares - minted quantity of pool's GS LP tokens
    event DepositNoPull(address indexed pool, uint256 shares);

    /// @dev Emitted when withdrawing CFMM LP tokens previously provided as liquidity from a pool
    /// @param pool - address of pool redeeming GS LP tokens for CFMM LP tokens
    /// @param assets - quantity of CFMM LP tokens withdrawn from pool
    event WithdrawNoPull(address indexed pool, uint256 assets);

    /// @dev Emitted when depositing reserve tokens as liquidity in a pool
    /// @param pool - address of pool redeeming GS LP tokens for CFMM LP tokens
    /// @param reserves - quantity of reserve tokens deposited in pool
    /// @param shares - minted quantity of pool's GS LP tokens representing the reserves deposit
    event DepositReserve(address indexed pool, uint256[] reserves, uint256 shares);

    /// @dev Emitted when withdrawing reserve tokens previously provided as liquidity from a pool
    /// @param pool - address of pool redeeming GS LP tokens for CFMM LP tokens
    /// @param reserves - quantity of reserve tokens withdrawn from pool
    /// @param assets - reserve tokens withdrawn from pool in terms of CFMM LP tokens
    event WithdrawReserve(address indexed pool, uint256[] reserves, uint256 assets);

    /// @dev Emitted when new loan in a pool is created. PositionManager owns new loan, owner owns new NFT that manages loan
    /// @param pool - address of pool where loan will be created
    /// @param owner - address of owner of newly minted NFT that manages newly created loan
    /// @param tokenId - unique id that identifies new loan in GammaPool
    /// @param refId - Reference id of post transaction activities attached to this loan
    event CreateLoan(address indexed pool, address indexed owner, uint256 tokenId, uint16 refId);

    /// @dev Emitted when increasing a loan's collateral amounts
    /// @param pool - address of pool collateral amounts are deposited to
    /// @param tokenId - id identifying loan in pool
    /// @param tokensHeld - new loan collateral amounts
    /// @param amounts - collateral amounts being deposited
    event IncreaseCollateral(address indexed pool, uint256 tokenId, uint128[] tokensHeld, uint256[] amounts);

    /// @dev Emitted when decreasing a loan's collateral amounts
    /// @param pool - address of pool collateral amounts are withdrawn from
    /// @param tokenId - id identifying loan in pool
    /// @param tokensHeld - new loan collateral amounts
    /// @param amounts - amounts of reserve tokens withdraws from loan
    event DecreaseCollateral(address indexed pool, uint256 tokenId, uint128[] tokensHeld, uint128[] amounts);

    /// @dev Emitted when re-balancing a loan's collateral amounts (swapping one collateral token for another)
    /// @param pool - loan's pool address
    /// @param tokenId - id identifying loan in pool
    /// @param tokensHeld - new loan collateral amounts
    event RebalanceCollateral(address indexed pool, uint256 tokenId, uint128[] tokensHeld);

    /// @dev Emitted when borrowing liquidity from a pool
    /// @param pool - address of pool whose liquidity was borrowed
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityBorrowed - liquidity borrowed in invariant terms
    /// @param amounts - liquidity borrowed in terms of reserve token amounts
    event BorrowLiquidity(address indexed pool, uint256 tokenId, uint256 liquidityBorrowed, uint256[] amounts);

    /// @dev Emitted when repaying liquidity debt from a pool
    /// @param pool - address of pool whose liquidity debt was paid
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityPaid - liquidity repaid in invariant terms
    /// @param amounts - liquidity repaid in terms of reserve token amounts
    event RepayLiquidity(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint256[] amounts);

    /// @dev Emitted when repaying liquidity debt from a pool
    /// @param pool - address of pool whose liquidity debt was paid
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityPaid - liquidity repaid in invariant terms
    /// @param amounts - liquidity repaid in terms of reserve token amounts
    event RepayLiquiditySetRatio(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint256[] amounts);

    /// @dev Emitted when repaying liquidity debt from a pool
    /// @param pool - address of pool whose liquidity debt was paid
    /// @param tokenId - id identifying loan in pool that will track liquidity debt
    /// @param liquidityPaid - liquidity repaid in invariant terms
    /// @param tokensHeld - new loan collateral amounts
    /// @param lpTokens - CFMM LP tokens used to repay liquidity debt
    event RepayLiquidityWithLP(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint128[] tokensHeld, uint256 lpTokens);

    event LoanUpdate(uint256 indexed tokenId, address indexed poolId, address indexed owner, uint128[] tokensHeld,
        uint256 liquidity, uint256 lpTokens, uint256 initLiquidity, uint128[] cfmmReserves);

    /// @dev Struct parameters for `depositNoPull` and `withdrawNoPull` functions. Depositing/Withdrawing CFMM LP tokens
    struct DepositWithdrawParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of GS LP tokens when depositing or of CFMM LP tokens when withdrawing
        address to;
        /// @dev CFMM LP tokens requesting to deposit or withdraw
        uint256 lpTokens;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
    }

    /// @dev Struct parameters for `depositReserves` function. Depositing reserve tokens
    struct DepositReservesParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of GS LP tokens when depositing
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens caller desires to deposit
        uint256[] amountsDesired;
        /// @dev minimum amounts of reserve tokens expected to have been deposited. Slippage protection
        uint256[] amountsMin;
    }

    /// @dev Struct parameters for `withdrawReserves` function. Withdrawing reserve tokens
    struct WithdrawReservesParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing
        address to;
        /// @dev amount of GS LP tokens that will be burned in the withdrawal
        uint256 amount;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn. Slippage protection
        uint256[] amountsMin;
    }

    /// @dev Struct parameters for `borrowLiquidity` function. Borrowing liquidity
    struct BorrowLiquidityParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan to which liquidity borrowed will be credited to
        uint256 tokenId;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens`. Slippage protection
        uint256[] minBorrowed;
    }

    /// @dev Struct parameters for `repayLiquidity` function. Repaying liquidity
    struct RepayLiquidityParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose liquidity debt will be paid
        uint256 tokenId;
        /// @dev liquidity debt to pay
        uint256 liquidity;
        /// @dev if true re-balance collateral to `ratio`
        bool isRatio;
        /// @dev If re-balancing to a desired ratio set this to the ratio you'd like, otherwise leave as an empty array
        uint256[] ratio;
        /// @dev fee on transfer for tokens[i]. Send empty array or array of zeroes if no token in pool has fee on transfer
        uint256[] fees;
        /// @dev collateralId - index of collateral token + 1
        uint256 collateralId;
        /// @dev to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint256[] minRepaid;
    }

    /// @dev Struct parameters for `repayLiquidityWithLP` function. Repaying liquidity with CFMM LP tokens
    struct RepayLiquidityWithLPParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose liquidity debt will be paid
        uint256 tokenId;
        /// @dev if using LP tokens to repay liquidity set this to > 0
        uint256 lpTokens;
        /// @dev collateralId - index of collateral token + 1
        uint256 collateralId;
        /// @dev to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
        address to;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of reserve tokens expected to have been used to repay the liquidity debt. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `increaseCollateral` and `decreaseCollateral` function.
    struct AddCollateralParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint256[] amounts;
        /// @dev ratio - ratio of loan collateral to be maintained after increasing collateral
        uint256[] ratio;
    }

    /// @dev Struct parameters for `increaseCollateral` and `decreaseCollateral` function.
    struct RemoveCollateralParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint128[] amounts;
        /// @dev ratio - ratio of loan collateral to be maintained after decreasing collateral
        uint256[] ratio;
    }

    /// @dev Struct parameters for `rebalanceCollateral` function.
    struct RebalanceCollateralParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev tokenId of loan whose collateral will change
        uint256 tokenId;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        int256[] deltas;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
    }

    /// @dev Struct parameters for `borrowAndRebalance` function.
    struct CreateLoanBorrowAndRebalanceParams {
        /// @dev protocolId of GammaPool (e.g. version of GammaPool)
        uint16 protocolId;
        /// @dev address of CFMM, along with protocolId can be used to calculate GammaPool address
        address cfmm;
        /// @dev receiver of reserve tokens when withdrawing collateral
        address to;
        /// @dev reference id of loan observer to track loan
        uint16 refId;
        /// @dev amounts of requesting to deposit as collateral for a loan or withdraw from a loan's collateral
        uint256[] amounts;
        /// @dev CFMM LP tokens requesting to borrow to short
        uint256 lpTokens;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens`. Slippage protection
        uint256[] minBorrowed;
        /// @dev minimum amounts of collateral expected to have after re-balancing collateral. Slippage protection
        uint128[] minCollateral;
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
    }

    /// @dev Struct parameters for `createLoanBorrowAndRebalance` function.
    struct BorrowAndRebalanceParams {
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
        /// @dev timestamp after which the transaction expires. Used to prevent stale transactions from executing
        uint256 deadline;
        /// @dev amounts of reserve tokens requesting to deposit as collateral for a loan
        uint256[] amounts;
        /// @dev Ratio to rebalance collateral to
        uint256[] ratio;
        /// @dev amounts of reserve tokens requesting to withdraw from a loan's collateral
        uint128[] withdraw;
        /// @dev minimum amounts of reserve tokens expected to have been withdrawn representing the `lpTokens` (borrowing). Slippage protection
        uint256[] minBorrowed;
        /// @dev amounts of reserve tokens to swap (>0 buy token, <0 sell token). At least one index value must be set to zero
        uint128[] minCollateral;
    }

    /// @return factory - factory contract that creates all GammaPools this PositionManager interacts with
    function factory() external view returns (address);

    // Short Gamma

    /// @dev Deposit CFMM LP tokens into a GammaPool and receive GS LP tokens
    /// @param params - struct containing parameters to identify a GammaPool to deposit CFMM LP tokens for GS LP tokens
    /// @return shares - GS LP token shares minted for depositing
    function depositNoPull(DepositWithdrawParams calldata params) external returns(uint256 shares);

    /// @dev Redeem GS LP tokens for CFMM LP tokens
    /// @param params - struct containing parameters to identify a GammaPool to redeem GS LP tokens for CFMM LP tokens
    /// @return assets - CFMM LP tokens received for GS LP tokens
    function withdrawNoPull(DepositWithdrawParams calldata params) external returns(uint256 assets);

    /// @dev Deposit reserve tokens into a GammaPool to receive GS LP tokens
    /// @param params - struct containing parameters to identify a GammaPool to deposit reserve tokens to
    /// @return reserves - reserve tokens deposited into GammaPool
    /// @return shares - GS LP token shares minted for depositing
    function depositReserves(DepositReservesParams calldata params) external returns (uint256[] memory reserves, uint256 shares);

    /// @dev Withdraw reserve tokens from a GammaPool
    /// @param params - struct containing parameters to identify a GammaPool to withdraw reserve tokens from
    /// @return reserves - reserve tokens withdrawn from GammaPool
    /// @return assets - CFMM LP token shares equivalent of reserves withdrawn from GammaPool
    function withdrawReserves(WithdrawReservesParams calldata params) external returns (uint256[] memory reserves, uint256 assets);

    // Long Gamma

    /// @notice Create a loan in GammaPool and turn it into an NFT issued to address `to`
    /// @dev Loans created here are actually owned by PositionManager and wrapped as an NFT issued to address `to`. But whoever holds NFT controls loan
    /// @param protocolId - protocolId (version) of GammaPool where loan will be created (used with `cfmm` to calculate GammaPool address)
    /// @param cfmm - address of CFMM, GammaPool is for (used with `protocolId` to calculate GammaPool address)
    /// @param to - recipient of NFT token that will be created
    /// @param refId - reference Id of loan observer to track loan lifecycle
    /// @param deadline - timestamp after which transaction expires. Can't be executed anymore. Removes stale transactions
    /// @return tokenId - tokenId of newly created loan
    function createLoan(uint16 protocolId, address cfmm, address to, uint16 refId, uint256 deadline) external returns(uint256 tokenId);

    /// @dev Borrow liquidity from GammaPool, can be used with a newly created loan or a loan already holding some liquidity debt
    /// @param params - struct containing params to identify a GammaPool and borrow liquidity from it
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function borrowLiquidity(BorrowLiquidityParams calldata params) external returns (uint256 liquidityBorrowed, uint256[] memory amounts);

    /// @dev Repay liquidity debt from GammaPool
    /// @param params - struct containing params to identify a GammaPool and loan to pay its liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function repayLiquidity(RepayLiquidityParams calldata params) external returns (uint256 liquidityPaid, uint256[] memory amounts);

    /// @dev Repay liquidity debt from GammaPool using CFMM LP tokens
    /// @param params - struct containing params to identify a GammaPool and loan to pay its liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return tokensHeld - reserve tokens used to pay liquidity debt
    function repayLiquidityWithLP(RepayLiquidityWithLPParams calldata params) external returns (uint256 liquidityPaid, uint128[] memory tokensHeld);

    /// @dev Increase loan collateral by depositing more reserve tokens
    /// @param params - struct containing params to identify a GammaPool and loan to add collateral to
    /// @return tokensHeld - new loan collateral token amounts
    function increaseCollateral(AddCollateralParams calldata params) external returns(uint128[] memory tokensHeld);

    /// @dev Decrease loan collateral by withdrawing reserve tokens
    /// @param params - struct containing params to identify a GammaPool and loan to remove collateral from
    /// @return tokensHeld - new loan collateral token amounts
    function decreaseCollateral(RemoveCollateralParams calldata params) external returns(uint128[] memory tokensHeld);

    /// @dev Re-balance loan collateral tokens by swapping one for another
    /// @param params - struct containing params to identify a GammaPool and loan to re-balance its collateral
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external returns(uint128[] memory tokensHeld);

    /// @notice Aggregate create loan, increase collateral, borrow collateral, and re-balance collateral into one transaction
    /// @dev Only create loan must be performed, the other transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokenId - tokenId of newly created loan
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams calldata params) external returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);

    /// @notice Aggregate increase collateral, borrow collateral, re-balance collateral, and decrease collateral into one transaction
    /// @dev All transactions are optional but must happen in the order described
    /// @param params - struct containing params to identify GammaPool to perform transactions on
    /// @return tokensHeld - new loan collateral token amounts
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for liquidity borrowed
    function borrowAndRebalance(BorrowAndRebalanceParams calldata params) external returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts);
}
