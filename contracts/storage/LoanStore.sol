// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ILoanStore.sol";

/// @title Implementation of ILoanStore interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice It's meant to be inherited by other contracts to create queries
abstract contract LoanStore is ILoanStore {

    mapping(uint256 => LoanInfo) internal loanToInfo;
    mapping(address => uint256[]) internal loansByOwner;
    mapping(address => mapping(address => uint256[])) internal loansByOwnerAndPool;

    address public owner;
    address public source;

    /// @dev Initializes the contract by setting `_owner`
    constructor(address _owner) {
        owner = _owner;
    }

    /// @dev See {ILoanStore-setSource}.
    function setSource(address _source) external virtual override {
        require(msg.sender == owner);
        source = _source;
    }

    /// @dev See {ILoanStore-addLoanToOwner}.
    function addLoanToOwner(address pool, uint256 tokenId, address user) public virtual override {
        require(msg.sender == source);
        uint256 byOwnerIdx = loansByOwner[user].length;
        uint256 byOwnerAndPoolIdx = loansByOwnerAndPool[user][pool].length;
        loanToInfo[tokenId] = LoanInfo({ pool: pool, byOwnerIdx: byOwnerIdx, byOwnerAndPoolIdx: byOwnerAndPoolIdx });
        loansByOwnerAndPool[user][pool].push(tokenId);
        loansByOwner[user].push(tokenId);
    }

    /// @dev See {ILoanStore-transferLoan}.
    function transferLoan(address from, address to, uint256 tokenId) public virtual override {
        require(msg.sender == source);
        LoanInfo memory _loanInfo = loanToInfo[tokenId];

        loansByOwnerAndPool[from][_loanInfo.pool][_loanInfo.byOwnerAndPoolIdx] = 0;
        loansByOwner[from][_loanInfo.byOwnerIdx] = 0;

        addLoanToOwner(_loanInfo.pool, tokenId, to);
    }

}
