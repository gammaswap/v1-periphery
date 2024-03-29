// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "@gammaswap/v1-core/contracts/base/AbstractGammaPoolFactory.sol";
import "./TestGammaPool.sol";
import "./ITestGammaPoolFactory.sol";

contract TestGammaPoolFactory is AbstractGammaPoolFactory {

    address[] public allPools;

    address public implementation;
    address public tester;
    address private protocol;

    constructor(address _feeToSetter) AbstractGammaPoolFactory(msg.sender, _feeToSetter, _feeToSetter) {
        tester = msg.sender;
    }

    function getProtocol(uint16) external virtual override view returns(address) {
        return implementation;
    }

    function getProtocolBeacon(uint16) external override view returns (address) {
        return address(0);
    }

    function isProtocolRestricted(uint16) external virtual override view returns(bool) {
        return false;
    }

    function setIsProtocolRestricted(uint16, bool) external virtual override {
    }

    function updateProtocol(uint16 _protocolId, address _newImplementation) external override virtual {
    }

    function addProtocol(address _protocol) external virtual override {
        implementation = _protocol;
    }

    function lockProtocol(uint16) external virtual override {
    }

    function createPool(uint16 protocolId, address cfmm, address[] calldata tokens, bytes calldata _data) external virtual override returns(address pool){
        bytes32 key = AddressCalculator.getGammaPoolKey(cfmm, protocolId);

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;
        pool = cloneDeterministic2(implementation, key);
        IGammaPool(pool).initialize(cfmm, tokens, decimals, 1e18, _data);

        getPool[key] = pool;

        allPools.push(pool);

        emit PoolCreated(pool, cfmm, protocolId, address(0), tokens, allPools.length);
    }

    function allPoolsLength() external virtual override view returns (uint256){
        return allPools.length;
    }

    function feeInfo() external view returns(address,uint256,uint256) {
        return (feeTo, fee, 0);
    }

    function setPoolFee(address _pool, address _to, uint16 _protocolFee, uint16 _origFeeShare, bool _isSet) external virtual override {
    }

    function getPoolFee(address _pool) external view returns (address _to, uint256 _protocolFee, uint256 _origFeeShare, bool _isSet) {
        return (feeTo, fee, 0, false);
    }

    function getPools(uint256, uint256) external view returns(address[] memory _pools) {
    }
}
