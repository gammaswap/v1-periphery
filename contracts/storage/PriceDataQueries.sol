// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./PriceStore.sol";
import "../interfaces/IPriceDataQueries.sol";

contract PriceDataQueries is IPriceDataQueries, PriceStore {

    /// @dev address of GammaPool factory contract
    address private immutable factory;

    uint256 public BLOCKS_PER_YEAR;

    /// @dev Initializes the contract by setting `_factory`, `_owner`, `_maxLen`, and `_frequency`.
    constructor(address _factory, address _owner, uint256 _maxLen, uint256 _frequency) PriceStore(_owner, _maxLen, _frequency) {
        factory = _factory;
    }

    /// @dev See {IPriceDataQueries-getTimeSeries}.
    function getTimeSeries(address pool, uint256 _frequency) external virtual override view returns(TimeSeriesData memory _data) {
        uint256 _firstIdx;
        uint256 _size;
        {
            uint256 len = timeSeries[pool].length;
            uint256 _maxLen = maxLen;
            _size = len;
            if(len == 0 || maxLen == 0) {
                return _data;
            } else if(len >= _maxLen) {
                _size = _maxLen;
                _firstIdx = len - _maxLen;
            }
            uint256 divisor;
            (_frequency, divisor) = getFrequency(_frequency);
            _data = createTimeSeriesData(_size, _size / divisor);
        }
        uint256 accFeeIndex;
        uint256 blockNumber;
        uint256 _nextTimestamp;
        uint256 j = 0;
        uint256 k = 0;
        for(uint256 i = _firstIdx; i < _firstIdx + _size;) { // hourly
            PriceInfo memory info = timeSeries[pool][i];
            _data.rawData[j] = createRawData(info);
            if(i == _firstIdx) {
                accFeeIndex = info.accFeeIndex * 1e6;
                blockNumber = info.blockNumber;
            } else {
                uint256 indexRate = calcIndexRate(accFeeIndex, blockNumber, info);
                accFeeIndex = info.accFeeIndex * 1e6;
                blockNumber = info.blockNumber;

                _data.rawData[j].indexRate = indexRate;

                if(info.timestamp >= _nextTimestamp) {
                    // start new bar
                    if(_nextTimestamp > 0) {
                        unchecked{
                            k++;
                        }
                    }
                    uint256 lastTimestamp = _frequency * info.timestamp / _frequency;
                    _nextTimestamp = lastTimestamp + _frequency;

                    _data.dailyPrices[k] = createTimeSeries(lastTimestamp, info.lastPrice);
                    _data.borrowRates[k] = createTimeSeries(lastTimestamp, info.borrowRate);
                    _data.utilRates[k] = createTimeSeries(lastTimestamp, info.utilRate);
                    _data.indexRates[k] = createTimeSeries(lastTimestamp, indexRate);
                } else {
                    // keep filling bar
                    _data.dailyPrices[k] = updateTimeSeries(_data.dailyPrices[k], info.lastPrice);
                    _data.borrowRates[k] = updateTimeSeries(_data.borrowRates[k], info.borrowRate);
                    _data.utilRates[k] = updateTimeSeries(_data.utilRates[k], info.utilRate);
                    _data.indexRates[k] = updateTimeSeries(_data.indexRates[k], indexRate);
                }
            }
            unchecked {
                j++;
                i++;
            }
        }
    }

    function getFrequency(uint256 _freq) internal pure returns(uint256 _frequency, uint256 divisor) {
        if(_freq == 1) {
            _frequency = 2 hours;
            divisor = 2;
        } else if(_freq == 2) {
            _frequency = 4 hours;
            divisor = 4;
        }  else if(_freq == 3) {
            _frequency = 6 hours;
            divisor = 6;
        }  else if(_freq == 4) {
            _frequency = 8 hours;
            divisor = 8;
        }  else if(_freq == 5) {
            _frequency = 12 hours;
            divisor = 12;
        }  else {
            _frequency = 1 days;
            divisor = 24;
        }
    }

    function createTimeSeriesData(uint256 rawLen, uint256 seriesLen) internal pure returns(TimeSeriesData memory _data) {
        _data = TimeSeriesData({
            rawData: new RawData[](rawLen),
            dailyPrices: new TimeSeries[](seriesLen),
            utilRates: new TimeSeries[](seriesLen),
            borrowRates: new TimeSeries[](seriesLen),
            indexRates: new TimeSeries[](seriesLen)
        });
    }

    function calcIndexRate(uint256 accFeeIndex, uint256 blockNumber, PriceInfo memory info) internal view returns(uint256 indexRate) {
        uint256 feeIndex = (info.accFeeIndex * 1e6 * 1e18 / accFeeIndex) - 1e18; // this is the fee index
        indexRate = feeIndex * BLOCKS_PER_YEAR / (info.blockNumber - blockNumber); // annualized
    }

    function createRawData(PriceInfo memory info) internal pure returns(RawData memory _rawData) {
        _rawData = RawData({
            timestamp: info.timestamp,
            blockNumber: info.blockNumber,
            utilRate: info.utilRate,
            borrowRate: info.borrowRate,
            accFeeIndex: info.accFeeIndex,
            lastPrice: info.lastPrice,
            indexRate: 0
        });
    }

    function updateTimeSeries(TimeSeries memory _ts, uint256 data) internal pure returns(TimeSeries memory) {
        if(data > _ts.high) {
            _ts.high = data;
        } else if(data < _ts.low) {
            _ts.low = data;
        }
        _ts.close = data;
        return _ts;
    }

    function createTimeSeries(uint256 timestamp, uint256 data) internal pure returns(TimeSeries memory _timeSeries) {
        _timeSeries = TimeSeries({
            timestamp: timestamp,
            open: data,
            high: data,
            low: data,
            close: data
        });
    }
}
