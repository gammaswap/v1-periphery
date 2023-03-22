// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";

/// @title Interface for IPositionManagerQueries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Defines external functions used by PositionManager to query pools and loans
interface IPositionManagerQueries {
    /// @notice Loans exist in owner's loan array for a pool in the order they're created. Index = 0 is the first loan created
    /// @dev Get loans from specific GammaPool belonging to owner. If a loan is transferred to another address, that index in the array points to 0
    /// @param owner - owner of loans to query loans for
    /// @param pool - GammaPool to look for loans belonging to owner
    /// @param start - start index of owner's loan array from `pool`
    /// @param end - end index of owner's loan array from `pool`
    /// @return _loans - loans belonging to user for specific gammaPool
    function getLoansByOwnerAndPool(address owner, address pool, uint256 start, uint256 end) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @notice Loans exist in owner's loan array in the order they're created.
    /// @dev Get loans belonging to owner. If a loan is transferred to another address, that index in the array points to 0
    /// @param owner - owner of loans to query loans for
    /// @param start - start index of owner's loan array
    /// @param end - end index of owner's loan array
    /// @return _loans - loans belonging to user
    function getLoansByOwner(address owner, uint256 start, uint256 end) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @notice The order of the pools in the array is the order in which they were created. (e.g. index 0 is first pool created)
    /// @dev Get list of pools from start index to end index (inclusive)
    /// @param start - start index of owner's loan array
    /// @param end - end index of owner's loan array
    /// @return _pools - pools with current data
    function getPools(uint256 start, uint256 end) external view returns(IGammaPool.PoolData[] memory _pools);

    /// @dev Get pools by pool address
    /// @param poolAddresses - array of pool address to query
    /// @return _pools - pools with current data
    function getPoolsByAddresses(address[] calldata poolAddresses) external view returns(IGammaPool.PoolData[] memory _pools);

    /// @dev Get pools with LP balance from user listed in the poolAddresses array
    /// @param poolAddresses - array of pool address
    /// @param owner - user's address who owns the pool
    /// @return _pools - pools with current data
    /// @return _balances - balances with current data
    function getPoolsWithOwnerLPBalance(address[] calldata poolAddresses, address owner) external view returns(IGammaPool.PoolData[] memory _pools, uint256[] memory _balances);
}
