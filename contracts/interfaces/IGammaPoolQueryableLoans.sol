// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";

/// @title Interface for IGammaPoolQueryableLoans
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Defines external functions used by PositionManager to query pools and loans
interface IGammaPoolQueryableLoans {
    /// @notice Loans are added to owner's loan array for a pool in the order they're created. Index = 0 is the first loan created
    /// @dev Get loans from specific GammaPool belonging to owner.
    /// @param owner - owner of loans to query loans for
    /// @param pool - GammaPool to look for loans belonging to owner
    /// @param start - start index of owner's loan array from `pool`
    /// @param end - end index of owner's loan array from `pool`
    /// @return _loans - loans belonging to user for specific gammaPool
    function getLoansByOwnerAndPool(address owner, address pool, uint256 start, uint256 end) external view returns(IGammaPool.LoanData[] memory _loans);

    /// @notice Loans are added to owner's loan array in the order they're created.
    /// @dev Get loans belonging to owner
    /// @param owner - owner of loans to query loans for
    /// @param start - start index of owner's loan array
    /// @param end - end index of owner's loan array
    /// @return _loans - loans belonging to user
    function getLoansByOwner(address owner, uint256 start, uint256 end) external view returns(IGammaPool.LoanData[] memory _loans);

}
