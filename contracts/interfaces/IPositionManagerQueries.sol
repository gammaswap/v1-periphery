// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolFactory.sol";

/// @title Interface for IPositionManagerQueries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Defines external functions used by PositionManager to query pools and loans
interface IPositionManagerQueries {
    /// @dev Struct to store loan reference information for a user
    struct LoanInfo {
        /// @dev GammaPool address of loan
        address poolId;
        /// @dev tokenId identifier of loan
        uint256 tokenId;
    }

    /// @dev Get loans from specific GammaPool belonging to owner
    /// @param owner - owner of loans to query loans for
    /// @param pool - GammaPool to look for loans belonging to owner
    /// @param start - start index of owner's loan array from `pool`
    /// @param end - end index of owner's loan array from `pool`
    /// @return _loans - loans belonging to user for specific gammaPool
    function getLoansByOwnerAndPool(address owner, address pool, uint256 start, uint256 end) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @dev Get loans belonging to owner
    /// @param owner - owner of loans to query loans for
    /// @param start - start index of owner's loan array
    /// @param end - end index of owner's loan array
    /// @return _loans - loans belonging to user
    function getLoansByOwner(address owner, uint256 start, uint256 end) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @dev Get loans belonging to owner
    /// @param start - start index of owner's loan array
    /// @param end - end index of owner's loan array
    /// @return _pools - pools with current data
    function getPools(uint256 start, uint256 end) external view returns(IGammaPool.PoolData[] memory _pools);

    /// @dev Get loans belonging to owner
    /// @param poolAddresses - start index of owner's loan array
    /// @return _pools - pools with current data
    function getPoolsByAddresses(address[] calldata poolAddresses) external view returns(IGammaPool.PoolData[] memory _pools);
}
