// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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

    /// @dev See {IPriceStore-setSource}.
    function setSource(address _source) external;

    /// @dev See {IPriceStore-addPriceInfo}.
    function addPriceInfo(address pool) external;

    function setMaxLen(uint256 _maxLen) external;

    function setFrequency(uint256 _frequency) external;
}
