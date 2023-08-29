// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IStakingRouter {
  function stakeLpForAccount(address, address, uint256) external;
  function stakeLoanForAccount(address, address, uint256) external;
  function unstakeLpForAccount(address, address, uint256) external;
  function unstakeLoanForAccount(address, address, uint256) external;
}