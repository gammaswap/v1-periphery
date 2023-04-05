// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/utils/TwoStepOwnable.sol";
import "../interfaces/IPriceStore.sol";

/// @title Implementation of ILoanStore interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice It's meant to be inherited by other contracts to create queries
abstract contract PriceStore is IPriceStore, TwoStepOwnable {

    /// @dev mapping of GammaPools to raw data point information
    mapping(address => PriceInfo[]) public timeSeries;

    /// @dev source of raw data updates
    address public source;

    /// @dev maximum data points per GammaPool. Once it reaches this limit start removing old data points
    uint256 public maxLen;

    /// @dev timestamp of next raw data point
    uint256 public nextTimestamp;

    /// @dev frequency of raw data intervals. E.g. 1 hour, 2 hours, etc. (Should be Enum)
    uint256 public frequency;

    /// @dev Initializes the contract by setting `owner`, `maxLen`, and `frequency`
    constructor(address _owner, uint256 _maxLen, uint256 _frequency) TwoStepOwnable(_owner) {
        maxLen = _maxLen;
        frequency = getFrequency(_frequency);
    }

    function getFrequency(uint256 _frequency) internal virtual pure returns(uint256) {
        if(_frequency == 0) {
            return 1 hours;
        }
        return _frequency;
    }

    /// @dev See {IPriceStore-setSource}.
    function setSource(address _source) external virtual override onlyOwner {
        source = _source;
    }

    /// @dev See {IPriceStore-setFrequency}.
    function setFrequency(uint256 _frequency) external virtual override onlyOwner {
        frequency = getFrequency(_frequency);
    }

    /// @dev See {IPriceStore-setMaxLen}.
    function setMaxLen(uint256 _maxLen) external virtual override onlyOwner {
        maxLen = _maxLen;
    }

    /// @dev See {IPriceStore-addPriceInfo}.
    function addPriceInfo(address pool) public virtual override {
        require(msg.sender == source, "SOURCE"); // only source can update
        uint256 currTime = block.timestamp;
        uint256 _nextTimestamp = nextTimestamp;
        if(currTime < _nextTimestamp) { // don't update if not crossed next timestamp
            return;
        }

        uint256 _frequency = frequency; // save gas
        uint256 lastTimestamp =  (currTime / _frequency) * _frequency; // round down to nearest timestamp
        nextTimestamp = lastTimestamp + _frequency; // add seconds to next timestamp

        IGammaPool.RateData memory data = IGammaPool(pool).getLatestRates();

        PriceInfo memory info = PriceInfo({
            timestamp: uint32(lastTimestamp),
            blockNumber: uint32(data.currBlockNumber),
            utilRate: uint16(data.utilizationRate / 1e14), // shrink to two decimal percentage points (0.01% to 100%)
            borrowRate: uint16(data.borrowRate / 1e16), // shrink to two decimal points (1% to 60000%)
            accFeeIndex: uint64(data.accFeeIndex / 1e6), // shrink to 10 decimal points
            lastPrice: uint96(data.lastPrice)
        });

        uint256 len = timeSeries[pool].length;
        if(len >= maxLen) { // remove data points older than maxLen
            delete timeSeries[pool][len - maxLen];
        }

        timeSeries[pool].push(info);
    }

    /// @dev See {IPriceStore-size}.
    function size(address pool) external virtual override view returns(uint256) {
        return timeSeries[pool].length;
    }

    /// @dev See {IPriceStore-getTimeSeriesAt}.
    function getTimeSeriesAt(address pool, uint256 index) external virtual override view returns(PriceInfo memory data) {
        return timeSeries[pool][index];
    }
}
