// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "@gammaswap/v1-core/contracts/base/AbstractGammaPoolFactory.sol";
import "./TestGammaPool.sol";
import "./ITestGammaPoolFactory.sol";

contract TestGammaPoolFactory is AbstractGammaPoolFactory {

    address[] public allPools;

    address public implementation;
    address public tester;
    address private protocol;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;
        owner = msg.sender;
        tester = msg.sender;
    }

    function getProtocol(uint16) external virtual override view returns(address) {
        return implementation;
    }

    function isProtocolRestricted(uint16) external virtual override view returns(bool) {
        return false;
    }

    function setIsProtocolRestricted(uint16, bool) external virtual override {
    }

    function addProtocol(address _protocol) external virtual override {
        implementation = _protocol;
    }

    function removeProtocol(uint16) external virtual override {
        implementation = address(0);
    }

    function createPool(uint16 protocolId, address cfmm, address[] calldata tokens, bytes calldata) external virtual override returns(address pool){
        bytes32 key = AddressCalculator.getGammaPoolKey(cfmm, protocolId);

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;
        pool = cloneDeterministic(implementation, key);
        IGammaPool(pool).initialize(cfmm, tokens, decimals);

        getPool[key] = pool;

        allPools.push(pool);

        emit PoolCreated(pool, cfmm, protocolId, address(0), tokens, allPools.length);
    }

    function allPoolsLength() external virtual override view returns (uint256){
        return allPools.length;
    }

    function feeInfo() external virtual override view returns(address,uint256){
        return (feeTo, fee);
    }
}
