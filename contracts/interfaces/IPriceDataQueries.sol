// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title IPriceDataQueries interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface of PriceDataQueries contract that will perform historical price queries
interface IPriceDataQueries {

    /// @dev Struct to store data points in candle bars
    struct Candle {
        uint256 timestamp;
        uint256 open;
        uint256 high;
        uint256 low;
        uint256 close;
    }

    /// @dev Struct to store raw time series data obtained from GammaPool
    struct PriceData {
        /// @dev Timestamp of datapoint
        uint256 timestamp;
        /// @dev Timestamp of datapoint
        uint256 blockNumber;
        /// @dev Utilization rate of GammaPool
        uint256 utilRate;
        /// @dev Yield in CFMM since last update (cfmmRate = 1 + yield), 281k with 9 decimals at uint48
        uint256 borrowRate;
        /// @dev YIeld of GammaPool since last update (feeIndex = (1 + borrowRate) * (1 + cfmmRate)
        uint256 accFeeIndex;
        /// @dev Add loan to mappings by user
        uint256 lastPrice; // 340 billion billion is uint128, 79 billion is uint96, 309 million is uint88, 1.2 million is uint80
        /// @dev YIeld of GammaPool since last update (feeIndex = (1 + borrowRate) * (1 + cfmmRate)
        uint256 indexRate;
    }

    /// @dev Struct to store all time series data in arrays
    struct TimeSeries {
        PriceData[] priceSeries;
        Candle[] dailyPrices;
        Candle[] utilRates;
        Candle[] borrowRates;
        Candle[] indexRates;
    }

    function getTimeSeries(address gammaPool, uint256 _frequency) external view returns(TimeSeries memory _timeSeries);
}
