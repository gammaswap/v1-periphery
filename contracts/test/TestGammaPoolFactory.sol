pragma solidity ^0.8.0;

import "../libraries/PoolAddress.sol";
import "./TestGammaPool.sol";

contract TestGammaPoolFactory {
    function create(
        address cfmm,
        uint24 protocol
    ) internal returns (address pool) {
        pool = address(new TestGammaPool{salt: PoolAddress.getPoolKey(cfmm, protocol)}());
    }
}
