// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TestERC20 is ERC20 {
  constructor() ERC20("TestERC20", "TE2") {}
}
