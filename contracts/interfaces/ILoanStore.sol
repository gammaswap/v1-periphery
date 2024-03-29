// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Interface for Loan Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface to interact with contract that stores all loans on chain, if enabled in PositionManager
interface ILoanStore {

    /// @dev Struct to store identifiable information about loan to perform queries in PositionManager
    struct LoanInfo {
        /// @dev Address of pool loan belongs to
        address pool;
        /// @dev Add loan to mappings by user
        uint256 byOwnerAndPoolIdx;
        /// @dev Add loan to mappings by user
        uint256 byOwnerIdx;
    }

    /// @dev Add loan to mappings by user so that they can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function addLoanToOwner(address pool, uint256 tokenId, address owner) external;

    /// @dev Transfer loan identified by `tokenId` from address `from` to another address `to`
    /// @param from - address transferring loan
    /// @param to - address receiving loan
    /// @param tokenId - unique identifier of loan
    function transferLoan(address from, address to, uint256 tokenId) external;

    /// @param _source - address supplying loan information
    function setSource(address _source) external;
}
