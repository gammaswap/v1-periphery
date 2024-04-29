// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./IPositionManager.sol";

/// @title Interface for extending PositionManager with auto stake/unstake capability
/// @author Simon Mall
/// @dev This should be used along with IPositionManager to define a contract
interface IAutoStakable {
  /// @dev Set staking router contract address
  /// @dev Requires admin permission
  /// @param _stakingRouter Staking Router contract address
  function setStakingRouter(address _stakingRouter) external;

  /// @dev Deposit reserve tokens into a GammaPool and stake GS LP tokens
  /// @dev See more {IPositionManager-depositReserves}
  /// @param params - struct containing parameters to identify a GammaPool to deposit reserve tokens to
  /// @param stakingRouter - address of router used for staking contracts
  /// @return reserves - reserve tokens deposited into GammaPool
  /// @return shares - GS LP token shares minted for depositing
  function depositReservesAndStake(IPositionManager.DepositReservesParams calldata params, address stakingRouter) external returns(uint256[] memory reserves, uint256 shares);

  /// @dev Unstake GS LP tokens from staking router and withdraw reserve tokens from a GammaPool
  /// @dev See more {IPositionManager-withdrawReserves}
  /// @param params - struct containing parameters to identify a GammaPool to withdraw reserve tokens from
  /// @param stakingRouter - address of router used for staking contracts
  /// @return reserves - reserve tokens withdrawn from GammaPool
  /// @return assets - CFMM LP token shares equivalent of reserves withdrawn from GammaPool
  function withdrawReservesAndUnstake(IPositionManager.WithdrawReservesParams calldata params, address stakingRouter) external returns (uint256[] memory reserves, uint256 assets);
}