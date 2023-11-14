// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "../storage/PriceDataQueries.sol";

contract TestPriceDataQueries is PriceDataQueries {
    constructor(uint256 blocksPerYear, address _owner, uint256 _maxLen, uint256 _frequency)
        PriceDataQueries(blocksPerYear, _owner, _maxLen, _frequency) {
    }

    function testUpdateCandle(Candle memory c, uint256 v) external virtual returns(Candle memory){
        return updateCandle(c, v);
    }

    function testCreateCandle(uint256 ts, uint256 v) external virtual returns(Candle memory){
        return createCandle(ts, v);
    }
}
