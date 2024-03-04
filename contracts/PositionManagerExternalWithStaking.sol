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
        (loanLiquidity,tokensHeld) = rebalanceCollateralExternally(gammaPool, params.tokenId, params.amounts, params.lpTokens, params.to, params.data, params.minCollateral);
        _logPrice(gammaPool);
    }
}