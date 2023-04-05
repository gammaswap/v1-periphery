// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./PriceStore.sol";
import "../interfaces/IPriceDataQueries.sol";

/// @title PriceDataQueries contract that implements IPriceDataQueries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Performs historical price queries from price data stored in PriceStore
contract PriceDataQueries is IPriceDataQueries, PriceStore {

    /// @dev Number of blocks per year in network
    uint256 public immutable BLOCKS_PER_YEAR;

    /// @dev Initializes the contract by setting `_owner`, `_maxLen`, and `_frequency`.
    constructor(uint256 blocksPerYear, address _owner, uint256 _maxLen, uint256 _frequency) PriceStore(_owner, _maxLen, _frequency) {
        BLOCKS_PER_YEAR = blocksPerYear;
    }

    /// @dev See {IPriceDataQueries-getTimeSeries}.
    function getTimeSeries(address pool, uint256 _frequency) external virtual override view returns(TimeSeries memory _data) {
        require(_frequency > 0 || _frequency < 25, "FREQUENCY");
        uint256 _firstIdx;
        uint256 _size;
        {
            uint256 len = priceSeries[pool].length;
            uint256 _maxLen = maxLen;
            _size = len;
            if(len == 0 || maxLen == 0) {
                return _data;
            } else if(len >= _maxLen) {
                _size = _maxLen;
                unchecked{
                    _firstIdx = len - _maxLen;
                }
            } else {
                _size = len;
            }
            if(_size / _frequency == 0) {
                return _data;
            }
            _data = createTimeSeries(_size, _size / _frequency); // _frequency is multiple of the raw data frequency
            unchecked{
                _frequency = _frequency * frequency; // frequency of bars is a multiple of the frequency of raw data
            }
        }
        uint256 accFeeIndex;
        uint256 blockNumber;
        uint256 _nextTimestamp;
        uint256 j = 0;
        uint256 k = 0;
        unchecked{
            _size = _firstIdx + _size;
        }
        for(uint256 i = _firstIdx; i < _size;) {
            PriceInfo memory info = priceSeries[pool][i];
            _data.priceSeries[j] = createPriceData(info);
            if(i == _firstIdx) {
                accFeeIndex = info.accFeeIndex * 1e6;
                blockNumber = info.blockNumber;
            } else {
                uint256 indexRate = calcIndexRate(accFeeIndex, blockNumber, info);
                accFeeIndex = info.accFeeIndex * 1e6;
                blockNumber = info.blockNumber;

                _data.priceSeries[j].indexRate = indexRate;

                if(info.timestamp >= _nextTimestamp) {
                    // start new bar
                    if(_nextTimestamp > 0) {
                        unchecked{
                            k++;
                        }
                    }
                    uint256 lastTimestamp = _frequency * info.timestamp / _frequency;
                    unchecked{
                        _nextTimestamp = lastTimestamp + _frequency;
                    }

                    _data.dailyPrices[k] = createCandle(lastTimestamp, info.lastPrice);
                    _data.borrowRates[k] = createCandle(lastTimestamp, info.borrowRate);
                    _data.utilRates[k] = createCandle(lastTimestamp, info.utilRate);
                    _data.indexRates[k] = createCandle(lastTimestamp, indexRate);
                } else {
                    // keep filling bar
                    _data.dailyPrices[k] = updateCandle(_data.dailyPrices[k], info.lastPrice);
                    _data.borrowRates[k] = updateCandle(_data.borrowRates[k], info.borrowRate);
                    _data.utilRates[k] = updateCandle(_data.utilRates[k], info.utilRate);
                    _data.indexRates[k] = updateCandle(_data.indexRates[k], indexRate);
                }
            }
            unchecked {
                j++;
                i++;
            }
        }
    }

    function createTimeSeries(uint256 priceSeriesLen, uint256 seriesLen) internal pure returns(TimeSeries memory) {
        return TimeSeries({
            priceSeries: new PriceData[](priceSeriesLen),
            dailyPrices: new Candle[](seriesLen),
            utilRates: new Candle[](seriesLen),
            borrowRates: new Candle[](seriesLen),
            indexRates: new Candle[](seriesLen)
        });
    }

    function calcIndexRate(uint256 accFeeIndex, uint256 blockNumber, PriceInfo memory info) internal view returns(uint256 indexRate) {
        uint256 feeIndex = (info.accFeeIndex * 1e6 * 1e18 / accFeeIndex) - 1e18; // this is the fee index
        indexRate = feeIndex * BLOCKS_PER_YEAR / (info.blockNumber - blockNumber); // annualized
    }

    function createPriceData(PriceInfo memory info) internal pure returns(PriceData memory) {
        return PriceData({
            timestamp: info.timestamp,
            blockNumber: info.blockNumber,
            utilRate: info.utilRate,
            borrowRate: info.borrowRate,
            accFeeIndex: info.accFeeIndex,
            lastPrice: info.lastPrice,
            indexRate: 0
        });
    }

    function updateCandle(Candle memory c, uint256 v) internal pure returns(Candle memory) {
        if(v > c.high) {
            c.high = v;
        } else if(v < c.low) {
            c.low = v;
        }
        c.close = v;
        return c;
    }

    function createCandle(uint256 timestamp, uint256 v) internal pure returns(Candle memory) {
        return Candle({
            timestamp: timestamp,
            open: v,
            high: v,
            low: v,
            close: v
        });
    }
}
