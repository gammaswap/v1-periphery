// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceDataQueries {

    /// @dev Struct to store identifiable information about loan to perform queries in PositionManager
    struct TimeSeries {
        uint256 timestamp;
        uint256 open;
        uint256 high;
        uint256 low;
        uint256 close;
    }
    struct RawData {
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
        uint256 lastPx; // 340 billion billion is uint128, 79 billion is uint96, 309 million is uint88, 1.2 million is uint80
        /// @dev YIeld of GammaPool since last update (feeIndex = (1 + borrowRate) * (1 + cfmmRate)
        uint256 indexRate;
    }
    struct TimeSeriesData {
        RawData[] rawData;
        TimeSeries[] dailyPrices;
        TimeSeries[] utilRates;
        TimeSeries[] borrowRates;
        TimeSeries[] indexRates;
    }

    function getTimeSeries(address gammaPool, uint256 _frequency) external view returns(TimeSeriesData memory _timeSeries);
}
