// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./interfaces/IStakingRouter.sol";
import "./PositionManager.sol";

contract PositionManagerWithStaking is PositionManager {
    IStakingRouter stakingRouter;

    constructor(address _factory, address _WETH, address _dataStore, address _priceStore) PositionManager(_factory, _WETH, _dataStore, _priceStore) {}

    function setStakingRouter(address _stakingRouter) external onlyOwner {
        stakingRouter = IStakingRouter(_stakingRouter);
    }

    function depositNoPull(DepositWithdrawParams calldata params) external override isExpired(params.deadline) returns(uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens); // send lp tokens to pool

        shares = IGammaPool(gammaPool).depositNoPull(address(stakingRouter));
        emit DepositNoPull(gammaPool, shares);

        stakingRouter.stakeLpForAccount(params.to, gammaPool, shares);
    }

    /// @dev See {IPositionManager-withdrawNoPull}.
    function withdrawNoPull(DepositWithdrawParams calldata params) external override isExpired(params.deadline) returns(uint256 assets) {
        address user = msg.sender;

        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        stakingRouter.unstakeLpForAccount(user, gammaPool, params.lpTokens);

        send(gammaPool, user, gammaPool, params.lpTokens); // send gs tokens to pool
        assets = IGammaPool(gammaPool).withdrawNoPull(params.to);
        emit WithdrawNoPull(gammaPool, assets);
    }

    /// @dev See {IPositionManager-depositReserves}.
    function depositReserves(DepositReservesParams calldata params) external override isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(address(stakingRouter), params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocolId: params.protocolId, payer: msg.sender})));
        emit DepositReserve(gammaPool, reserves, shares);

        stakingRouter.stakeLpForAccount(params.to, gammaPool, shares);
    }

    /// @dev See {IPositionManager-withdrawReserves}.
    function withdrawReserves(WithdrawReservesParams calldata params) external override isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address user = msg.sender;

        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        stakingRouter.unstakeLpForAccount(user, gammaPool, params.amount);

        send(gammaPool, user, gammaPool, params.amount); // send gs tokens to pool
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        checkMinReserves(reserves, params.amountsMin);
        emit WithdrawReserve(gammaPool, reserves, assets);
    }
}