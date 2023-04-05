pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/storage/PriceDataQueries.sol";
import "../../contracts/test/TestGammaPool2.sol";

contract PriceDataQueriesTest is Test {

    TestGammaPool2 pool;
    PriceDataQueries pdq;
    address owner;
    address addr1;

    uint16 _protocolId;
    address _factory;
    address _longStrategy;
    address _shortStrategy;
    address _liquidationStrategy;

    function setUp() public {
        _protocolId = 1;
        _factory = vm.addr(1);
        _longStrategy = vm.addr(2);
        _shortStrategy = vm.addr(3);
        _liquidationStrategy = vm.addr(4);

        pool = new TestGammaPool2(_protocolId, _factory, _longStrategy, _shortStrategy, _liquidationStrategy);
        uint256 maxLen = 10;
        uint256 frequency = 1;
        pdq = new PriceDataQueries(address(this), maxLen, frequency);

        // new deployed contracts will have Test as owner
        owner = address(this);
        pdq.setSource(owner);
        addr1 = vm.addr(5);
    }

    function testSetSource() public {
        assertFalse(addr1 == pdq.source());
        pdq.setSource(addr1);
        assertEq(addr1, pdq.source());
    }
}
