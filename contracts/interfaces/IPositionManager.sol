// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

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
    event LoanUpdated(uint256 indexed tokenId, uint128[] tokensHeld, uint256 liquidity, uint256 lpTokens, uint256 rateIndex);
    event LoanUpdate(uint256 indexed tokenId, address indexed poolId, address indexed owner, uint128[] tokensHeld, uint256 liquidity, uint256 lpTokens, uint256 initLiquidity, uint256 lastPx);

    struct DepositWithdrawParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 lpTokens;
        uint256 deadline;
    }

    struct DepositReservesParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 deadline;
        uint256[] amountsDesired;
        uint256[] amountsMin;
    }

    struct WithdrawReservesParams {
        address cfmm;
        address to;
        uint16 protocolId;
        uint256 amount;
        uint256 deadline;
        uint256[] amountsMin;
    }

    struct BorrowLiquidityParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 tokenId;
        uint256 lpTokens;
        uint256 deadline;
        uint256[] minBorrowed;
    }

    struct RepayLiquidityParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 tokenId;
        uint256 liquidity;
        uint256 deadline;
        uint256[] minRepaid;
    }

    struct AddRemoveCollateralParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 tokenId;
        uint256 deadline;
        uint256[] amounts;
    }

    struct RebalanceCollateralParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 tokenId;
        uint256 deadline;
        int256[] deltas;
        uint128[] minCollateral;
    }

    struct CreateLoanBorrowAndRebalanceParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 lpTokens;
        uint256 deadline;
        uint256[] amounts;
        uint256[] minBorrowed;
        int256[] deltas;
        uint128[] minCollateral;
    }

    struct BorrowAndRebalanceParams {
        uint16 protocolId;
        address cfmm;
        uint256 tokenId;
        uint256 lpTokens;
        uint256 deadline;
        uint256[] amounts;
        uint256[] minBorrowed;
        int256[] deltas;
        uint128[] minCollateral;
    }

    struct RebalanceRepayAndWithdrawParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 tokenId;
        uint256 liquidity;
        uint256 deadline;
        uint256[] amounts;
        uint256[] withdraw;
        uint256[] minRepaid;
        int256[] deltas;
        uint128[] minCollateral;
    }

    function factory() external view returns (address);

    //Short Gamma
    function depositNoPull(DepositWithdrawParams calldata params) external returns(uint256 shares);
    function withdrawNoPull(DepositWithdrawParams calldata params) external returns(uint256 assets);
    function depositReserves(DepositReservesParams calldata params) external returns (uint256[] memory reserves, uint256 shares);
    function withdrawReserves(WithdrawReservesParams calldata params) external returns (uint256[] memory reserves, uint256 assets);

    //Long Gamma
    function createLoan(uint16 protocolId, address cfmm, address to, uint256 deadline) external returns(uint256 tokenId);
    function borrowLiquidity(BorrowLiquidityParams calldata params) external returns (uint256[] memory amounts);
    function repayLiquidity(RepayLiquidityParams calldata params) external returns (uint256 liquidityPaid, uint256[] memory amounts);
    function increaseCollateral(AddRemoveCollateralParams calldata params) external returns(uint128[] memory tokensHeld);
    function decreaseCollateral(AddRemoveCollateralParams calldata params) external returns(uint128[] memory tokensHeld);
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external returns(uint128[] memory tokensHeld);
    function createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams calldata params) external virtual returns(uint256 tokenId, uint128[] memory tokensHeld, uint256[] memory amounts);
    function borrowAndRebalance(BorrowAndRebalanceParams calldata params) external virtual returns(uint128[] memory tokensHeld, uint256[] memory amounts);
    function rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams calldata params) external virtual returns(uint128[] memory tokensHeld, uint256 liquidityPaid, uint256[] memory amounts);
}
