// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./TestPoolViewer.sol";

contract TestPoolViewer2 is TestPoolViewer {

    uint256 public utilRate;
    uint256 public borrowRate;
    uint256 public accFeeIndex;
    uint256 public lastPrice;

    function setLatestRates(uint256 _utilRate, uint256 _borrowRate, uint256 _accFeeIndex, uint256 _lastPrice) external virtual {
        utilRate = _utilRate;
        borrowRate = _borrowRate;
        accFeeIndex = _accFeeIndex;
        lastPrice = _lastPrice;
    }

    function getLatestRates(address pool) external virtual override view returns(IGammaPool.RateData memory data) {
        data.utilizationRate = utilRate;
        data.borrowRate = borrowRate;
        data.accFeeIndex = accFeeIndex;
        data.currBlockNumber = block.number;
        data.lastPrice = lastPrice;
    }
}
