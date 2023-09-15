// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title Interface for Staking Router contract
/// @author Simon Mall
/// @dev Interface for staking router contract that deposits and withdraws from GammaSwap staking pools
interface IStakingRouter {
  /// @dev Stake GS_LP tokens on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _amount Amount of GS_LP tokens to stake
  function stakeLpForAccount(address _account, address _gsPool, uint256 _amount) external;

  /// @dev Stake loan on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _loanId NFT loan id
  function stakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external;

  /// @dev Unstake GS_LP tokens on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _amount Amount of GS_LP tokens to unstake
  function unstakeLpForAccount(address _account, address _gsPool, uint256 _amount) external;

  /// @dev Unstake loan on behalf of user
  /// @param _account User address for query
  /// @param _gsPool GammaPool address
  /// @param _loanId NFT loan id
  function unstakeLoanForAccount(address _account, address _gsPool, uint256 _loanId) external;
}