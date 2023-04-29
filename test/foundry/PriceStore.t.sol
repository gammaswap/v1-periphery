pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/test/TestGammaPool2.sol";
import "../../contracts/interfaces/IPriceStore.sol";
import "../../contracts/test/TestPriceStore.sol";

contract PriceStoreTest is Test {

    TestGammaPool2 pool;
    PriceStore ps;
    address owner;
    address addr1;
    address _pool2;

    uint16 _protocolId;
    address _factory;
    address _longStrategy;
    address _shortStrategy;
    address _liquidationStrategy;

    uint256 frequency;
    uint256 maxLen;

    function setUp() public {
        _protocolId = 1;
        _factory = vm.addr(1);
        _longStrategy = vm.addr(2);
        _shortStrategy = vm.addr(3);
        _liquidationStrategy = vm.addr(4);

        pool = new TestGammaPool2(_protocolId, _factory, _longStrategy, _shortStrategy, _liquidationStrategy);
        _pool2 = address(new TestGammaPool2(_protocolId, _factory, _longStrategy, _shortStrategy, _liquidationStrategy));
        maxLen = 10;
        frequency = 300;
        ps = new TestPriceStore(address(this), maxLen, frequency);

        // new deployed contracts will have Test as owner
        owner = address(this);
        ps.setSource(owner);
        addr1 = vm.addr(5);
    }

    function testSetSource() public {
        assertFalse(addr1 == ps.source());
        ps.setSource(addr1);
        assertEq(addr1, ps.source());
    }

    function testFailSetSource() public {
        assertFalse(addr1 == ps.source());
        vm.prank(addr1);
        ps.setSource(addr1);
    }

    function testSetFrequency(uint256 var1) public {
        assertEq(frequency, ps.frequency());
        ps.setFrequency(var1);
        if(var1 > 0) {
            assertEq(var1, ps.frequency());
        } else {
            assertEq(1 hours, ps.frequency());
        }
        ps.setFrequency(7890);
        assertEq(7890, ps.frequency());
        ps.setFrequency(0);
        assertEq(1 hours, ps.frequency());
        ps.setFrequency(2 hours);
        assertEq(2 hours, ps.frequency());
        ps.setFrequency(1 days);
        assertEq(1 days, ps.frequency());
        ps.setFrequency(1 hours);
        assertEq(3600, ps.frequency());
        ps.setFrequency(6 hours);
        assertEq(6 hours, ps.frequency());
        ps.setFrequency(0);
        assertEq(3600, ps.frequency());
    }

    function testFailSetFrequency(uint256 var1) public {
        assertEq(frequency, ps.frequency());
        vm.prank(addr1);
        ps.setFrequency(var1);
    }

    function testSetMaxLen(uint256 var1) public {
        assertEq(maxLen, ps.maxLen());
        ps.setMaxLen(var1);
        assertEq(var1, ps.maxLen());
    }

    function testFailSetMaxLen(uint256 var1) public {
        assertEq(maxLen, ps.maxLen());
        vm.prank(addr1);
        ps.setMaxLen(var1);
    }

    function testFailAddPriceInfo(uint256 var1) public {
        vm.prank(addr1);
        ps.addPriceInfo(address(pool));
    }

    function testAddPriceInfo2(uint8 len, uint8 _maxLen) public {
        uint256 utilRate0 = 1e18 / 100;
        uint256 borrowRate0 = 1e18 / 100;
        uint256 accFeeIndex0 = 1e18;
        uint256 lastPrice0 = 1e18;
        pool.setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);

        ps.setMaxLen(_maxLen);

        address _pool = address(pool);

        assertEq(0, ps.size(_pool));

        for(uint256 i = 0; i < len; i++) {
            vm.roll(i*27); // 12 seconds
            vm.warp(i*300);
            ps.addPriceInfo(_pool);
        }

        uint256 _len = len;
        if(_maxLen == 0) {
            _len = 0;
        }
        assertEq(_len, ps.size(_pool));
    }

    function testAddPriceInfo(uint256 var1) public {
        address _pool = address(pool);

        uint256 utilRate0 = 1e18 / 100;
        uint256 borrowRate0 = 1e18 / 100;
        uint256 accFeeIndex0 = 1e18;
        uint256 lastPrice0 = 1e18;
        pool.setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);

        ps.addPriceInfo(_pool);
        assertEq(1,ps.size(_pool));

        IPriceStore.PriceInfo memory ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        ps.addPriceInfo(_pool);
        assertEq(1,ps.size(_pool));
        assertEq(300,ps.nextTimestamp(_pool));
        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        assertEq(0,ps.size(_pool2));
        ps.addPriceInfo(_pool2);
        assertEq(1,ps.size(_pool2));
        assertEq(300,ps.nextTimestamp(_pool2));

        vm.roll(10); // 120 seconds
        vm.warp(200);

        ps.addPriceInfo(_pool);
        assertEq(1,ps.size(_pool));
        assertEq(300,ps.nextTimestamp(_pool));
        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        vm.roll(25); // 180 seconds

        ps.addPriceInfo(_pool);
        assertEq(1,ps.size(_pool));

        vm.roll(26); // 12 seconds

        ps.addPriceInfo(_pool);
        assertEq(1,ps.size(_pool));

        vm.roll(27); // 12 seconds
        vm.warp(300);

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        pool.setLatestRates(2*utilRate0, 2*borrowRate0, 2*accFeeIndex0, 2*lastPrice0);

        ps.addPriceInfo(_pool);
        assertEq(2,ps.size(_pool));
        assertEq(600,ps.nextTimestamp(_pool));

        assertEq(1,ps.size(_pool2));
        assertEq(300,ps.nextTimestamp(_pool2));

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        ts = ps.getPriceAt(_pool,1);
        assertEq(ts.timestamp,300);
        assertEq(ts.blockNumber,27);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        ps.addPriceInfo(_pool);
        assertEq(2,ps.size(_pool));

        ts = ps.getPriceAt(_pool,1);
        assertEq(ts.timestamp,300);
        assertEq(ts.blockNumber,27);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        vm.roll(28); // 12 seconds
        vm.warp(600);

        ps.addPriceInfo(_pool);
        assertEq(3,ps.size(_pool));

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        ts = ps.getPriceAt(_pool,1);
        assertEq(ts.timestamp,300);
        assertEq(ts.blockNumber,27);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        ts = ps.getPriceAt(_pool,2);
        assertEq(ts.timestamp,600);
        assertEq(ts.blockNumber,28);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        vm.roll(29); // 12 seconds
        vm.warp(901);

        pool.setLatestRates(3*utilRate0, 3*borrowRate0, 3*accFeeIndex0, 3*lastPrice0);

        ps.addPriceInfo(_pool);
        assertEq(4,ps.size(_pool));

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        ts = ps.getPriceAt(_pool,1);
        assertEq(ts.timestamp,300);
        assertEq(ts.blockNumber,27);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        ts = ps.getPriceAt(_pool,2);
        assertEq(ts.timestamp,600);
        assertEq(ts.blockNumber,28);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        ts = ps.getPriceAt(_pool,3);
        assertEq(ts.timestamp,900);
        assertEq(ts.blockNumber,29);
        assertEq(ts.utilRate,3*utilRate0/1e14);
        assertEq(ts.borrowRate,3*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,3*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,3*lastPrice0);

        vm.roll(30); // 12 seconds
        vm.warp(1200);
        ps.addPriceInfo(_pool);
        assertEq(5,ps.size(_pool));

        ps.addPriceInfo(_pool2);
        assertEq(2,ps.size(_pool2));
        assertEq(1500,ps.nextTimestamp(_pool2));

        vm.roll(31); // 12 seconds
        vm.warp(1500);
        ps.addPriceInfo(_pool);
        assertEq(6,ps.size(_pool));

        vm.roll(32); // 12 seconds
        vm.warp(1800);
        ps.addPriceInfo(_pool);
        assertEq(7,ps.size(_pool));

        vm.roll(33); // 12 seconds
        vm.warp(2100);
        ps.addPriceInfo(_pool);
        assertEq(8,ps.size(_pool));

        vm.roll(34); // 12 seconds
        vm.warp(2400);
        ps.addPriceInfo(_pool);
        assertEq(9,ps.size(_pool));

        vm.roll(35); // 12 seconds
        vm.warp(2800);
        ps.addPriceInfo(_pool);
        assertEq(10,ps.size(_pool));

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,1);
        assertEq(ts.utilRate,utilRate0/1e14);
        assertEq(ts.borrowRate,borrowRate0/1e16);
        assertEq(ts.accFeeIndex,accFeeIndex0/1e6);
        assertEq(ts.lastPrice,lastPrice0);

        ts = ps.getPriceAt(_pool,9);
        assertEq(ts.timestamp,2700);
        assertEq(ts.blockNumber,35);
        assertEq(ts.utilRate,3*utilRate0/1e14);
        assertEq(ts.borrowRate,3*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,3*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,3*lastPrice0);

        pool.setLatestRates(4*utilRate0, 4*borrowRate0, 4*accFeeIndex0, 4*lastPrice0);

        vm.roll(36); // 12 seconds
        vm.warp(3000);

        ps.addPriceInfo(_pool);
        assertEq(11,ps.size(_pool));

        ts = ps.getPriceAt(_pool,9);
        assertEq(ts.timestamp,2700);
        assertEq(ts.blockNumber,35);
        assertEq(ts.utilRate,3*utilRate0/1e14);
        assertEq(ts.borrowRate,3*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,3*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,3*lastPrice0);

        ts = ps.getPriceAt(_pool,10);
        assertEq(ts.timestamp,3000);
        assertEq(ts.blockNumber,36);
        assertEq(ts.utilRate,4*utilRate0/1e14);
        assertEq(ts.borrowRate,4*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,4*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,4*lastPrice0);

        ts = ps.getPriceAt(_pool,1);
        assertEq(ts.timestamp,300);
        assertEq(ts.blockNumber,27);
        assertEq(ts.utilRate,2*utilRate0/1e14);
        assertEq(ts.borrowRate,2*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,2*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,2*lastPrice0);

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,0);
        assertEq(ts.utilRate,0);
        assertEq(ts.borrowRate,0);
        assertEq(ts.accFeeIndex,0);
        assertEq(ts.lastPrice,0);

        vm.roll(37); // 12 seconds
        vm.warp(3300);

        ps.addPriceInfo(_pool);
        assertEq(12,ps.size(_pool));

        ts = ps.getPriceAt(_pool,0);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,0);
        assertEq(ts.utilRate,0);
        assertEq(ts.borrowRate,0);
        assertEq(ts.accFeeIndex,0);
        assertEq(ts.lastPrice,0);

        ts = ps.getPriceAt(_pool,1);
        assertEq(ts.timestamp,0);
        assertEq(ts.blockNumber,0);
        assertEq(ts.utilRate,0);
        assertEq(ts.borrowRate,0);
        assertEq(ts.accFeeIndex,0);
        assertEq(ts.lastPrice,0);

        ts = ps.getPriceAt(_pool,10);
        assertEq(ts.timestamp,3000);
        assertEq(ts.blockNumber,36);
        assertEq(ts.utilRate,4*utilRate0/1e14);
        assertEq(ts.borrowRate,4*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,4*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,4*lastPrice0);

        ts = ps.getPriceAt(_pool,11);
        assertEq(ts.timestamp,3300);
        assertEq(ts.blockNumber,37);
        assertEq(ts.utilRate,4*utilRate0/1e14);
        assertEq(ts.borrowRate,4*borrowRate0/1e16);
        assertEq(ts.accFeeIndex,4*accFeeIndex0/1e6);
        assertEq(ts.lastPrice,4*lastPrice0);/**/
    }
}