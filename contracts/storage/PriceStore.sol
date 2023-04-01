// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "../interfaces/IPriceStore.sol";

/// @title Implementation of ILoanStore interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice It's meant to be inherited by other contracts to create queries
abstract contract PriceStore is IPriceStore {

    mapping(address => PriceInfo[]) internal timeSeries;

    address public owner;
    address public source;

    uint256 public maxLen;
    uint256 public nextTimestamp;
    uint256 public frequency; // should be ENUM, e.g. 1 hours;, 15 minutes, 2/4/6/8/12 hours

    /// @dev Initializes the contract by setting `owner`, `maxLen`, and `frequency`
    constructor(address _owner, uint256 _maxLen, uint256 _frequency) {
        owner = _owner;
        maxLen = _maxLen;
        frequency = _frequency;
    }

    /// @dev See {IPriceStore-setSource}.
    function setSource(address _source) external virtual override {
        require(msg.sender == owner);
        source = _source;
    }

    /// @dev See {IPriceStore-setFrequency}.
    function setFrequency(uint256 _frequency) external virtual override {
        require(msg.sender == owner);
        frequency = _frequency;
    }

    /// @dev See {IPriceStore-setMaxLen}.
    function setMaxLen(uint256 _maxLen) external virtual override {
        require(msg.sender == owner);
        maxLen = _maxLen;
    }

    /// @dev See {IPriceStore-addPriceInfo}.
    function addPriceInfo(address pool) public virtual override {
        require(msg.sender == source);
        uint256 currTime = block.timestamp;
        uint256 _nextTimestamp = nextTimestamp;
        if(currTime < _nextTimestamp) {
            return;
        }

        uint256 _frequency = frequency;
        uint256 lastTimestamp = _frequency * currTime / _frequency;
        _nextTimestamp = lastTimestamp + _frequency;
        nextTimestamp = _nextTimestamp;

        uint256 lastPx = IGammaPool(pool).getLastCFMMPrice();
        uint256 accFeeIndex;
        uint256 borrowRate;
        uint256 currBlockNumber;
        (accFeeIndex,,,borrowRate,,currBlockNumber) = IGammaPool(pool).getLatestRates(); // should also get lastPx here and utilRate

        PriceInfo memory info = PriceInfo({
            timestamp: uint32(lastTimestamp),
            blockNumber: uint32(currBlockNumber),
            utilRate: 0, // need to get this
            borrowRate: uint16(borrowRate / 1e16), // this can be shrunk to 2 decimals
            accFeeIndex: uint64(accFeeIndex / 1e6),
            lastPx: uint96(lastPx)
        });

        uint256 len = timeSeries[pool].length;
        if(len >= maxLen) {
            delete timeSeries[pool][len - maxLen];
        }

        timeSeries[pool].push(info);
    }

}
