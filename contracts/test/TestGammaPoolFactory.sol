pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "./TestGammaPool.sol";
import "./ITestGammaPoolFactory.sol";

contract TestGammaPoolFactory is ITestGammaPoolFactory{

    address public override feeToSetter;
    address public override owner;
    address public override feeTo;
    uint256 public override fee = 5 * (10**16); //5% of borrowed interest gains by default

    mapping(bytes32 => address) public override getPool;//all GS Pools addresses can be predetermined

    address[] public allPools;

    Parameters private _params;

    address public override longStrategy;
    address public override shortStrategy;
    address public override tester;
    address private protocol;

    constructor(address _feeToSetter, address _longStrategy, address _shortStrategy, address _protocol) {
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;
        owner = msg.sender;
        longStrategy = _longStrategy;
        shortStrategy = _shortStrategy;
        tester = msg.sender;
        protocol = _protocol;
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

    function createPool(CreatePoolParams calldata params) external virtual override returns(address pool){
        _params = Parameters({ cfmm: params.cfmm,
            protocolId: params.protocol,
            tokens: params.tokens,
            protocol: protocol });
        bytes32 key = AddressCalculator.getGammaPoolKey(_params.cfmm, _params.protocolId);
        pool = address(new TestGammaPool{salt: key}());
        delete _params;
        getPool[key] = pool;

        allPools.push(pool);

        emit PoolCreated(pool, params.cfmm, params.protocol, protocol, allPools.length);
    }

    function allPoolsLength() external virtual override view returns (uint){
        return allPools.length;
    }

    function feeInfo() external virtual override view returns(address,uint){
        return (feeTo, fee);
    }

    function parameters() external virtual override view returns (address cfmm, uint24 protocolId, address[] memory tokens, address _protocol){
        cfmm = _params.cfmm;
        protocolId = _params.protocolId;
        tokens = _params.tokens;
        _protocol = _params.protocol;
    }
}
