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
        /// @dev Data used to contrcut the candle bars
        PriceData[] priceSeries;
        /// @dev Candle bars of prices of CFMM
        Candle[] prices;
        /// @dev Candle bars of utilization rate of GammaPool
        Candle[] utilRates;
        /// @dev Candle bars of annual borrow rate of GammaPool
        Candle[] borrowRates;
        /// @dev Candle bars of accrued interest rate of GammaPool within candle interval (annualized)
        Candle[] indexRates;
    }

    /// @dev Return candle bar information containing prices, utilization rates, borrowRates, accrued return, in `_frequency` intervals
    /// @notice The `_frequency` interval can't be smaller than the interval at which data is stored in the PriceStore contract
    /// @param pool - Address of GammaPool to get candle bars for
    /// @param _frequency - interval of the candle bars, specified as multiples of the `frequency` time interval of data in the PriceStore
    /// @return _timeSeries - time series struct containing candle bars and the price data used to construct the candle bars
    function getCandleBars(address pool, uint256 _frequency) external view returns(TimeSeries memory _timeSeries);
}
