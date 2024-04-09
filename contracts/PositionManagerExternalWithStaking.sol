// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolExternal.sol";

import "./interfaces/IPositionManagerExternal.sol";
import "./PositionManagerWithStaking.sol";

/// @title PositionManagerExternalWithStaking, concrete implementation of IPositionManagerExternal
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Inherits PositionManager functionality from PositionManagerWithStaking and defines functionality to rebalance
/// @notice loan collateral using external contracts by calling GammaPool::rebalanceExternally()
contract PositionManagerExternalWithStaking is PositionManagerWithStaking, IPositionManagerExternal {

    /// @dev Constructs the PositionManagerWithStaking contract.
    /// @param _factory Address of the contract factory.
    /// @param _WETH Address of the Wrapped Ether (WETH) contract.
    constructor(address _factory, address _WETH) PositionManagerWithStaking(_factory, _WETH) {}

    /// @dev Flash loan pool's collateral and/or lp tokens to external address. Rebalanced loan collateral is acceptable
    /// @dev in  repayment of flash loan. Function can be used for other purposes besides rebalancing collateral.
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - unique id identifying loan
    /// @param amounts - collateral amounts being flash loaned
    /// @param lpTokens - amount of CFMM LP tokens being flash loaned
    /// @param to - address that will receive flash loan swaps and potentially rebalance loan's collateral
    /// @param data - optional bytes parameter for custom user defined data
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return loanLiquidity - updated loan liquidity, includes flash loan fees
    /// @return tokensHeld - updated collateral token amounts backing loan
    function rebalanceCollateralExternally(address gammaPool, uint256 tokenId, uint128[] memory amounts, uint256 lpTokens, address to, bytes calldata data, uint128[] memory minCollateral) internal virtual returns(uint256 loanLiquidity, uint128[] memory tokensHeld) {
        (loanLiquidity, tokensHeld) = IGammaPoolExternal(gammaPool).rebalanceExternally(tokenId, amounts, lpTokens, to, data);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RebalanceCollateralExternally(gammaPool, tokenId, loanLiquidity, tokensHeld);
    }

    /// @dev See {IPositionManagerExternal-rebalanceCollateralExternally}.
    function rebalanceCollateralExternally(RebalanceCollateralExternallyParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint256 loanLiquidity, uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (loanLiquidity,tokensHeld) = rebalanceCollateralExternally(gammaPool, params.tokenId, params.amounts, params.lpTokens, params.rebalancer, params.data, params.minCollateral);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManagerExternal-createLoanBorrowAndRebalanceExternally}.
    function createLoanBorrowAndRebalanceExternally(CreateLoanBorrowAndRebalanceExternallyParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokenId = createLoan(gammaPool, params.to, params.refId);
        tokensHeld = increaseCollateral(gammaPool, tokenId, params.amounts, new uint256[](0), new uint128[](0));
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, tokenId, params.lpTokens, new uint256[](0), params.minBorrowed, params.maxBorrowed, new uint128[](0));
        }
        if(params.rebalancer != address(0)) {
            (,tokensHeld) = rebalanceCollateralExternally(gammaPool, tokenId, tokensHeld, 0, params.rebalancer, params.data, params.minCollateral);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManagerExternal-rebalanceExternallyAndRepayLiquidity}.
    function rebalanceExternallyAndRepayLiquidity(RebalanceExternallyAndRepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.rebalancer != address(0)) {
            rebalanceCollateralExternally(gammaPool, params.tokenId, params.amounts, 0, params.rebalancer, params.data, params.minCollateral);
        }
        if(params.withdraw.length > 0) {
            // if partial repay
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, 0, address(0), params.minRepaid);
            decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw, new uint256[](0), new uint128[](0));
        } else {
            // if full repay
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, params.collateralId, params.to, params.minRepaid);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManagerExternal-borrowAndRebalanceExternally}.
    function borrowAndRebalanceExternally(BorrowAndRebalanceExternallyParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        bool isWithdrawCollateral = params.withdraw.length != 0;
        if(params.amounts.length != 0) {
            tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts, new uint256[](0), new uint128[](0));
        }
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts, tokensHeld) = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens, new uint256[](0), params.minBorrowed, params.maxBorrowed, new uint128[](0));
        }
        if(params.rebalancer != address(0) && tokensHeld.length != 0) {
            (,tokensHeld) = rebalanceCollateralExternally(gammaPool, params.tokenId, tokensHeld, 0, params.rebalancer, params.data, params.minCollateral);
        }
        if(isWithdrawCollateral) {
            tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw, new uint256[](0), new uint128[](0));
        }
        _logPrice(gammaPool);
    }
}
