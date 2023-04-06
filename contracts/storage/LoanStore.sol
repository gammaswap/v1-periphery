// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@gammaswap/v1-core/contracts/utils/TwoStepOwnable.sol";
import "../interfaces/ILoanStore.sol";

/// @title Implementation of ILoanStore interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice It's meant to be inherited by other contracts to create queries
abstract contract LoanStore is ILoanStore, TwoStepOwnable {

    /// @dev Maps loan's tokenId to loanInfo for easier query
    mapping(uint256 => LoanInfo) internal loanToInfo;
    /// @dev Maps user address to array of loan tokenIds belonging to user for easier query
    mapping(address => uint256[]) internal loansByOwner;
    /// @dev Maps user address to map of GammaPool address to array of tokenIds belonging to user at specific GammaPool for easier query
    mapping(address => mapping(address => uint256[])) internal loansByOwnerAndPool;

    /// @dev Source address providing loan ownership information (executes addToLoanOwner and transferLoan)
    address public source;

    /// @dev Initializes the contract by setting `_owner`
    constructor(address _owner) TwoStepOwnable(_owner) {
    }

    /// @dev See {ILoanStore-setSource}.
    function setSource(address _source) external virtual override onlyOwner {
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
