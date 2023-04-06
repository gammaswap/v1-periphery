// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title IPriceStore interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface of PriceStore contract that will store price information for historical price queries
interface IPriceStore {

    /// @dev Struct to store identifiable information about loan to perform queries in PositionManager
    struct PriceInfo {
        /// @dev Timestamp of datapoint
        uint32 timestamp;
        /// @dev block number of datapoint
        uint32 blockNumber;
        /// @dev Utilization rate of GammaPool
        uint16 utilRate;
        /// @dev Yield in CFMM since last update (cfmmRate = 1 + yield), 281k with 9 decimals at uint48
        uint16 borrowRate;
        /// @dev YIeld of GammaPool since last update (feeIndex = (1 + borrowRate) * (1 + cfmmRate)
        uint64 accFeeIndex;
        /// @dev Add loan to mappings by user
        uint96 lastPrice; // 340 billion billion is uint128, 79 billion is uint96, 309 million is uint88, 1.2 million is uint80
    }

    /// @dev Set address that will supply the PriceStore with price information about a GammaPool
    /// @notice This is the address that can call the addPriceInfo() function to store price information
    /// @param _source - Address that calls addPrice() function to store price information
    function setSource(address _source) external;

    /// @dev Add price information from GammaPool. This calls the GammaPool with address `pool` to get the latest price information from it
    /// @notice Price information is added at frequency set by frequency state variable.
    /// @param pool - Address of GammaPoool to retrieve and store price information for in a price series array for it.
    function addPriceInfo(address pool) external;

    /// @dev Set the maximum length to store information for the price series of a GammaPool
    /// @notice If array of price series grows past _maxLen, values older than _maxLen spots back will be deleted with every update
    /// @param _maxLen - the maximum length of the price series array to hold information
    function setMaxLen(uint256 _maxLen) external;

    /// @dev Set the frequency at which to store information in seconds.
    /// @notice If set to zero the frequency is 1 hour in seconds (3600 seconds).
    /// @param _frequency - frequency to store information in seconds (e.g. 1 hour - 3600 seconds)
    function setFrequency(uint256 _frequency) external;

    /// @dev Get length of price series array of GammaPool with address `_pool`
    /// @param _pool - address of GammaPool to retrieve information for
    /// @return size - size of price series array of `_pool`
    function size(address _pool) external view returns(uint256);

    /// @dev Get price information at index of PriceInfo array of GammaPool with address `pool`
    /// @param pool - address of the GammaPool to get price information from
    /// @param index - index of price series array to retrieve information from
    /// @return data - PriceInfo struct containing price information at `index` of price series array of `pool`
    function getPriceAt(address pool, uint256 index) external view returns(PriceInfo memory data);

}
