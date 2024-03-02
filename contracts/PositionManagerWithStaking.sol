// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./interfaces/IStakingPoolRouter.sol";
import "./interfaces/IAutoStakable.sol";
import "./PositionManager.sol";

/// @title PositionManagerWithStaking
/// @author Simon Mall
/// @dev Extension of PositionManager that adds staking and unstaking functionality for automated operations.
contract PositionManagerWithStaking is PositionManager, IAutoStakable {
    IStakingPoolRouter stakingRouter;

    /// @dev Constructs the PositionManagerWithStaking contract.
    /// @param _factory Address of the contract factory.
    /// @param _WETH Address of the Wrapped Ether (WETH) contract.
    constructor(address _factory, address _WETH) PositionManager(_factory, _WETH) {}

    /// @dev See {IAutoStakable-setStakingRouter}
    function setStakingRouter(address _stakingRouter) external onlyOwner {
        stakingRouter = IStakingPoolRouter(_stakingRouter);
    }

    /// @dev See {IAutoStakable-depositReservesAndStake}.
    function depositReservesAndStake(DepositReservesParams calldata params) external isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(address(stakingRouter), params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocolId: params.protocolId, payer: msg.sender})));

        stakingRouter.stakeLpForAccount(params.to, gammaPool, shares);
        emit DepositReserve(gammaPool, reserves, shares);
    }

    /// @dev See {IAutoStakable-withdrawReservesAndUnstake}.
    function withdrawReservesAndUnstake(WithdrawReservesParams calldata params) external isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address user = msg.sender;

        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        stakingRouter.unstakeLpForAccount(user, gammaPool, params.amount);

        send(gammaPool, msg.sender, gammaPool, params.amount);
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        checkMinReserves(reserves, params.amountsMin);
        emit WithdrawReserve(gammaPool, reserves, assets);
    }
}