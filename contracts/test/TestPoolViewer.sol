// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/base/PoolViewer.sol";

contract TestPoolViewer is PoolViewer {

    function loan(address pool, uint256 tokenId) external virtual override view returns(IGammaPool.LoanData memory _loanData)  {
        return IGammaPool(pool).loan(tokenId);
    }

    function getLatestPoolData(address pool) public virtual override view returns(IGammaPool.PoolData memory data) {
        return IGammaPool(pool).getPoolData();
    }

    function _getLastFeeIndex(address pool) internal virtual override view returns(IGammaPool.RateData memory data) {
    }

    function getLoansById(address pool, uint256[] calldata tokenIds, bool active) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        return IGammaPool(pool).getLoansById(tokenIds, active);
    }
}
