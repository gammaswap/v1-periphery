// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "@gammaswap/v1-core/contracts/base/AbstractGammaPoolFactory.sol";
import "./TestGammaPool.sol";
import "./ITestGammaPoolFactory.sol";

//contract TestGammaPoolFactory is ITestGammaPoolFactory{
contract TestGammaPoolFactory is AbstractGammaPoolFactory {

    address[] public allPools;

    //Parameters private _params;

    address public longStrategy;
    address public shortStrategy;
    address public tester;
    address private protocol;

    constructor(address _feeToSetter, address _longStrategy, address _shortStrategy, address _protocol, address _implementation) {
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;
        owner = msg.sender;
        longStrategy = _longStrategy;
        shortStrategy = _shortStrategy;
        tester = msg.sender;
        protocol = _protocol;
        implementation = _implementation;
    }

    function getProtocol(uint24 protocolId) external virtual override view returns(address) {
        return protocol;
    }

    function isProtocolRestricted(uint24 protocolId) external virtual override view returns(bool) {
        return false;
    }

    function setIsProtocolRestricted(uint24 protocolId, bool isRestricted) external virtual override {
    }

    function addProtocol(address _protocol) external virtual override {
    }

    function removeProtocol(uint24 protocolId) external virtual override {
    }

    function createPool2(CreatePoolParams calldata params) external virtual returns(address pool) {
        bytes32 key = AddressCalculator.getGammaPoolKey(params.cfmm, params.protocol);

        //IProtocol mProtocol = IProtocol(protocol);

        IGammaPool.InitializeParameters memory mParams = IGammaPool.InitializeParameters({
        cfmm: params.cfmm, protocolId: params.protocol, tokens: params.tokens, protocol: protocol,
        longStrategy: longStrategy, shortStrategy: shortStrategy});

        pool = cloneDeterministic(implementation, key);
        IGammaPool(pool).initialize(mParams);

        getPool[key] = pool;

        allPools.push(pool);

        emit PoolCreated(pool, params.cfmm, params.protocol, address(0), allPools.length);
    }/**/

    function createPool(CreatePoolParams calldata params) external virtual override returns(address pool){
        /*_params = Parameters({ cfmm: params.cfmm,
            protocolId: params.protocol,
            tokens: params.tokens,
            protocol: protocol });
        bytes32 key = AddressCalculator.getGammaPoolKey(_params.cfmm, _params.protocolId);
        pool = address(new TestGammaPool{salt: key}());
        delete _params;
        getPool[key] = pool;

        allPools.push(pool);

        emit PoolCreated(pool, params.cfmm, params.protocol, protocol, allPools.length);/**/
    }

    function allPoolsLength() external virtual override view returns (uint){
        return allPools.length;
    }

    function feeInfo() external virtual override view returns(address,uint){
        return (feeTo, fee);
    }

    /*cfunction parameters() external virtual override view returns (address cfmm, uint24 protocolId, address[] memory tokens, address _protocol){
        fmm = _params.cfmm;
        protocolId = _params.protocolId;
        tokens = _params.tokens;
        _protocol = _params.protocol;
    }/**/
}
