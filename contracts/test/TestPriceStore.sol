// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../storage/PriceStore.sol";

contract TestPriceStore is PriceStore {
    constructor(address _owner, uint256 _maxLen, uint256 _frequency) PriceStore(_owner, _maxLen, _frequency) {
    }
}
