// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./ITransfers.sol";

interface IPositionManager  is ITransfers {

    event DepositNoPull(address indexed pool, uint256 shares);
    event WithdrawNoPull(address indexed pool, uint256 assets);
    event DepositReserve(address indexed pool, uint256 reservesLen, uint256 shares);
    event WithdrawReserve(address indexed pool, uint256 reservesLen, uint256 assets);
    event CreateLoan(address indexed pool, address indexed owner, uint256 tokenId);
    event BorrowLiquidity(address indexed pool, uint256 tokenId, uint256 amountsLen);
    event RepayLiquidity(address indexed pool, uint256 tokenId, uint256 liquidityPaid, uint256 amountsLen);
    event IncreaseCollateral(address indexed pool, uint256 tokenId, uint256 tokensHeldLen);
    event DecreaseCollateral(address indexed pool, uint256 tokenId, uint256 tokensHeldLen);
    event RebalanceCollateral(address indexed pool, uint256 tokenId, uint256 tokensHeldLen);
    event PoolUpdated(uint256 lpTokenBalance, uint256 lpTokenBorrowed, uint256 lastBlockNumber, uint256 accFeeIndex,
    uint256 lastFeeIndex, uint256 lpTokenBorrowedPlusInterest, uint256 lpInvariant, uint256 lpBorrowedInvariant);
    event LoanCreated(address indexed caller, uint256 tokenId);
    event LoanUpdated(uint256 indexed tokenId, uint256[] tokensHeld, uint256 heldLiquidity, uint256 liquidity, uint256 lpTokens, uint256 rateIndex);

    struct DepositWithdrawParams {
        address cfmm;
        uint24 protocol;
        uint256 lpTokens;
        address to;
        uint256 deadline;
    }

    struct DepositReservesParams {
        address cfmm;
        uint256[] amountsDesired;
        uint256[] amountsMin;
        address to;
        uint24 protocol;
        uint256 deadline;
    }

    struct WithdrawReservesParams {
        address cfmm;
        uint24 protocol;
        uint256 amount;
        uint256[] amountsMin;
        address to;
        uint256 deadline;
    }

    struct BorrowLiquidityParams {
        address cfmm;
        uint24 protocol;
        uint256 tokenId;
        uint256 lpTokens;
        address to;
        uint256 deadline;
    }

    struct RepayLiquidityParams {
        address cfmm;
        uint24 protocol;
        uint256 tokenId;
        uint256 liquidity;
        address to;
        uint256 deadline;
    }

    struct AddRemoveCollateralParams {
        address cfmm;
        uint24 protocol;
        uint256 tokenId;
        uint256[] amounts;
        address to;
        uint256 deadline;
    }

    struct RebalanceCollateralParams {
        address cfmm;
        uint24 protocol;
        uint256 tokenId;
        int256[] deltas;
        uint256 liquidity;
        address to;
        uint deadline;
    }

    function factory() external view returns (address);

    //Short Gamma
    function depositNoPull(DepositWithdrawParams calldata params) external returns(uint256 shares);
    function withdrawNoPull(DepositWithdrawParams calldata params) external returns(uint256 assets);
    function depositReserves(DepositReservesParams calldata params) external returns (uint256[] memory reserves, uint256 shares);
    function withdrawReserves(WithdrawReservesParams calldata params) external returns (uint256[] memory reserves, uint256 assets);

    //Long Gamma
    function createLoan(address cfmm, uint24 protocol, address to, uint256 deadline) external returns(uint256 tokenId);
    function loan(address cfmm, uint24 protocol, uint256 tokenId) external view returns (uint256 id, address poolId,
        uint256[] memory tokensHeld, uint256 initLiquidity, uint256 liquidity, uint256 lpTokens, uint256 rateIndex);
    function borrowLiquidity(BorrowLiquidityParams calldata params) external returns (uint256[] memory amounts);
    function repayLiquidity(RepayLiquidityParams calldata params) external returns (uint256 liquidityPaid, uint256[] memory amounts);
    function increaseCollateral(AddRemoveCollateralParams calldata params) external returns(uint256[] memory tokensHeld);
    function decreaseCollateral(AddRemoveCollateralParams calldata params) external returns(uint256[] memory tokensHeld);
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external returns(uint256[] memory tokensHeld);
}
