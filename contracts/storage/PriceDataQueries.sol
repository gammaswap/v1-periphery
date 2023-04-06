// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./PriceStore.sol";
import "../interfaces/IPriceDataQueries.sol";

/// @title PriceDataQueries contract that implements IPriceDataQueries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Performs historical price queries from price data stored in PriceStore
/// @notice getCandleBars can return array elements with zero data. This is expected behavior
contract PriceDataQueries is IPriceDataQueries, PriceStore {

    /// @dev Number of blocks per year in network
    uint256 public immutable BLOCKS_PER_YEAR;

    /// @dev Initializes the contract by setting `blocks_per_year`, `_owner`, `_maxLen`, and `_frequency`.
    constructor(uint256 blocksPerYear, address _owner, uint256 _maxLen, uint256 _frequency) PriceStore(_owner, _maxLen, _frequency) {
        BLOCKS_PER_YEAR = blocksPerYear;
    }

    /// @dev See {IPriceDataQueries-getCandleBars}.
    /// @dev Candle bars arrays can have zero data fields at the last elements of the array since they're at least of size 2.
    /// @dev This is to avoid edge cases. Therefore candle bars can have 1 or 2 more elements than the source priceSeries data array returned
    function getCandleBars(address pool, uint256 _frequency) external virtual override view returns(TimeSeries memory _data) {
        require(_frequency > 0 && _frequency < 25, "FREQUENCY"); // can't rebuild candle bars to be greatr than 24 units of PriceStore data
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
            }
            uint256 tsSize = (_size / _frequency) + 2; // size of candle bars array is always at least size 2
            unchecked{
                _frequency = _frequency * frequency; // frequency of bars is a multiple of the frequency of raw data
            }
            _data = createTimeSeries(_size, tsSize); // _frequency is multiple of the raw data frequency
        }
        uint256 accFeeIndex;
        uint256 blockNumber;
        uint256 _nextTimestamp;
        uint256 indexRate;
        uint256 j = 0;
        uint256 k = 0;
        unchecked{
            _size = _firstIdx + _size;
        }
        for(uint256 i = _firstIdx; i < _size;) {
            PriceInfo memory info = priceSeries[pool][i];
            _data.priceSeries[j] = createPriceData(info);
            if(i == _firstIdx) {
                accFeeIndex = uint256(info.accFeeIndex) * 1e6;
                blockNumber = info.blockNumber;
            } else {
                indexRate = calcIndexRate(accFeeIndex, blockNumber, info);
                accFeeIndex = uint256(info.accFeeIndex) * 1e6;
                blockNumber = info.blockNumber;
            }
            _data.priceSeries[j].indexRate = indexRate;

            if(info.timestamp >= _nextTimestamp) {
                // start new bar
                if(_nextTimestamp > 0) { // don't increase first one
                    unchecked {
                        k++;
                    }
                }
                uint256 lastTimestamp = (info.timestamp / _frequency) * _frequency;
                unchecked {
                    _nextTimestamp = lastTimestamp + _frequency;
                }

                _data.prices[k] = createCandle(lastTimestamp, info.lastPrice);
                _data.borrowRates[k] = createCandle(lastTimestamp, info.borrowRate);
                _data.utilRates[k] = createCandle(lastTimestamp, info.utilRate);
                _data.indexRates[k] = createCandle(lastTimestamp, indexRate);
            } else {
                // keep filling bar
                _data.prices[k] = updateCandle(_data.prices[k], info.lastPrice);
                _data.borrowRates[k] = updateCandle(_data.borrowRates[k], info.borrowRate);
                _data.utilRates[k] = updateCandle(_data.utilRates[k], info.utilRate);
                _data.indexRates[k] = updateCandle(_data.indexRates[k], indexRate);
            }
            unchecked {
                j++;
                i++;
            }
        }
    }

    /// @dev create struct that will contain source time series data and candle bar time series data
    /// @notice Candle bars for prices, utilization rates, annualized borrow rates (excludes trading fees), and annualized GammaPool rates (trading fees + interest rates) charged to borrowers
    function createTimeSeries(uint256 priceSeriesLen, uint256 seriesLen) internal pure returns(TimeSeries memory) {
        return TimeSeries({
            priceSeries: new PriceData[](priceSeriesLen),
            prices: new Candle[](seriesLen),
            utilRates: new Candle[](seriesLen),
            borrowRates: new Candle[](seriesLen),
            indexRates: new Candle[](seriesLen)
        });
    }

    /// @dev Calculate index rate return in between the two updates (info.blockNumber and blockNumber)
    /// @param accFeeIndex - accrued fee index of GammaPool at beginning of period
    /// @param blockNumber - block number of beginning of period
    /// @param info - PriceInfo struct containing ending period accFeeIndex and blockNumber
    /// @return indexRate - annualized accrued fee return from GammaPool from `blockNumber` to `info.blockNumber`
    function calcIndexRate(uint256 accFeeIndex, uint256 blockNumber, PriceInfo memory info) internal view returns(uint256 indexRate) {
        uint256 feeIndex = (uint256(info.accFeeIndex) * 1e6 * 1e18) / accFeeIndex - 1e18; // this is the fee index
        indexRate = feeIndex * BLOCKS_PER_YEAR / (info.blockNumber - blockNumber); // annualized
    }

    /// @dev Create struct that will contain source time series data
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

    /// @dev Update candle bar's high, low, and close with latest value
    function updateCandle(Candle memory c, uint256 v) internal pure returns(Candle memory) {
        if(v > c.high) {
            c.high = v;
        } else if(v < c.low) {
            c.low = v;
        }
        c.close = v;
        return c;
    }

    /// @dev Create candle bar (timestamp, open, high, low, close) initialized to latest timestamp and value
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
