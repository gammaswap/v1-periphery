// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceStore {

    /// @dev See {IPriceStore-setSource}.
    function setSource(address _source) external;

    /// @dev See {IPriceStore-addPriceInfo}.
    function addPriceInfo(address pool) external;

    function setMaxLen(uint256 _maxLen) external;

    function setFrequency(uint256 _frequency) external;
}
