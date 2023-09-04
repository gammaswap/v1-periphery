pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/test/TestGammaPool2.sol";
import "../../contracts/interfaces/IPriceDataQueries.sol";
import "../../contracts/test/TestPriceDataQueries.sol";
import "../../contracts/test/TestPoolViewer2.sol";

contract PriceDataQueriesTest is Test {

    TestGammaPool2 pool;
    TestPriceDataQueries pdq;
    address _pool;
    address owner;
    address addr1;

    uint16 _protocolId;
    address _factory;
    address _borrowStrategy;
    address _repayStrategy;
    address _rebalanceStrategy;
    address _shortStrategy;
    address _liquidationStrategy;
    address _batchLiquidationStrategy;
    address _viewer;

    uint256 maxLen;
    uint256 frequency;
    uint256 blocksPerYear;

    function setUp() public {
        _protocolId = 1;
        _factory = vm.addr(1);
        _borrowStrategy = vm.addr(2);
        _shortStrategy = vm.addr(3);
        _liquidationStrategy = vm.addr(4);
        _repayStrategy = vm.addr(100);
        _rebalanceStrategy = vm.addr(111);
        _batchLiquidationStrategy = vm.addr(122);
        _viewer = address(new TestPoolViewer2());

        pool = new TestGammaPool2(_protocolId, _factory, _borrowStrategy, _repayStrategy, _rebalanceStrategy, _shortStrategy, _liquidationStrategy, _batchLiquidationStrategy, _viewer);
        _pool = address(pool);

        maxLen = 7 * 24; // 1 week
        frequency = 0;
        blocksPerYear = 60 * 60 * 24 * 365 / 12; // assumes 12 seconds per block
        pdq = new TestPriceDataQueries(blocksPerYear, address(this), maxLen, frequency);

        // new deployed contracts will have Test as owner
        owner = address(this);
        pdq.setSource(owner);
        addr1 = vm.addr(5);
    }

    function testFailGetCandleBarsFrequency0() public {
        pdq.getCandleBars(_pool, 0);
    }

    function testFailGetCandleBarsFrequency25() public {
        pdq.getCandleBars(_pool, 25);
    }

    function testCreateAndUpdateCandle(uint256 ts, uint256 v, uint256 u) public {
        IPriceDataQueries.Candle memory c = pdq.testCreateCandle(ts, v);
        assertEq(ts, c.timestamp);
        assertEq(v, c.open);
        assertEq(v, c.high);
        assertEq(v, c.low);
        assertEq(v, c.close);

        uint256 high = u > v ? u : v;
        uint256 low = u < v ? u : v;
        c = pdq.testUpdateCandle(c, u);
        assertEq(v, c.open);
        assertEq(high, c.high);
        assertEq(low, c.low);
        assertEq(u, c.close);
    }

    function testGetCandleBarsZeroLen() public {
        assertEq(0, pdq.size(_pool));
        IPriceDataQueries.TimeSeries memory ts = pdq.getCandleBars(_pool, 10);
        assertEq(0, ts.priceSeries.length);
        assertEq(0, ts.prices.length);
        assertEq(0, ts.utilRates.length);
        assertEq(0, ts.borrowRates.length);
        assertEq(0, ts.indexRates.length);
    }

    function testGetCandleBarsZeroMaxLen() public {
        assertEq(0, pdq.size(_pool));
        pdq.addPriceInfo(_pool);
        assertEq(1, pdq.size(_pool));

        IPriceDataQueries.TimeSeries memory ts = pdq.getCandleBars(_pool, 1);
        assertEq(1, ts.priceSeries.length);
        assertEq(3, ts.prices.length);
        assertEq(3, ts.utilRates.length);
        assertEq(3, ts.borrowRates.length);
        assertEq(3, ts.indexRates.length);

        pdq.setMaxLen(0);

        ts = pdq.getCandleBars(_pool, 10);
        assertEq(0, ts.priceSeries.length);
        assertEq(0, ts.prices.length);
        assertEq(0, ts.utilRates.length);
        assertEq(0, ts.borrowRates.length);
        assertEq(0, ts.indexRates.length);
    }

    function testGetCandleBarsRoundDownSize() public {
        assertEq(0, pdq.size(_pool));
        pdq.addPriceInfo(_pool);
        assertEq(1, pdq.size(_pool));

        IPriceDataQueries.TimeSeries memory ts = pdq.getCandleBars(_pool, 1);
        assertEq(1, ts.priceSeries.length);
        assertEq(3, ts.prices.length);
        assertEq(3, ts.utilRates.length);
        assertEq(3, ts.borrowRates.length);
        assertEq(3, ts.indexRates.length);

        ts = pdq.getCandleBars(_pool, 2);
        assertEq(1, ts.priceSeries.length);
        assertEq(2, ts.prices.length);
        assertEq(2, ts.utilRates.length);
        assertEq(2, ts.borrowRates.length);
        assertEq(2, ts.indexRates.length);
    }

    function testGetCandleBarsLenLtMaxLen() public {
        uint256 utilRate0 = 1e18 / 100;
        uint256 borrowRate0 = 1e18 / 100;
        uint256 accFeeIndex0 = 1e18;
        uint256 lastPrice0 = 1e18;
        TestPoolViewer2(pool.viewer()).setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);

        assertEq(0, pdq.size(_pool));
        pdq.addPriceInfo(_pool);
        assertEq(1, pdq.size(_pool));

        vm.roll(300); // 300 blocks is 1 hour
        vm.warp(3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(2, pdq.size(_pool));

        IPriceDataQueries.TimeSeries memory ts = pdq.getCandleBars(_pool, 1);
        assertEq(2, ts.priceSeries.length);
        assertEq(4, ts.prices.length);
        assertEq(4, ts.utilRates.length);
        assertEq(4, ts.borrowRates.length);
        assertEq(4, ts.indexRates.length);

        ts = pdq.getCandleBars(_pool, 3);
        assertEq(2, ts.priceSeries.length);
        assertEq(2, ts.prices.length);
        assertEq(2, ts.utilRates.length);
        assertEq(2, ts.borrowRates.length);
        assertEq(2, ts.indexRates.length);
    }

    function testGetCandleBarsLenGteMaxLen2(uint8 len, uint8 _maxLen) public {
        uint256 utilRate0 = 1e18 / 100;
        uint256 borrowRate0 = 1e18 / 100;
        uint256 accFeeIndex0 = 1e18;
        uint256 lastPrice0 = 1e18;
        TestPoolViewer2(pool.viewer()).setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);

        pdq.setMaxLen(_maxLen);

        assertEq(0, pdq.size(_pool));

        IPriceDataQueries.TimeSeries memory ts;

        for(uint256 i = 0; i < len; i++) {
            vm.roll(i*300); // 12 seconds
            vm.warp(i*3600);
            pdq.addPriceInfo(_pool);
        }

        uint256 _len = len;
        if(_maxLen == 0) {
            _len = 0;
        }
        assertEq(_len, pdq.size(_pool));

        uint256 _size = _len;
        if(_len == 0 || _maxLen == 0) {
            _size = 0;
        } else if(_len >= _maxLen) {
            _size = _maxLen;
        }

        for(uint256 _frequency = 1; _frequency <= 24; _frequency++) {
            uint256 tsSize = _size > 0 ? (_size / _frequency) + 2 : 0;

            ts = pdq.getCandleBars(_pool, _frequency);
            assertEq(_size, ts.priceSeries.length);
            assertEq(tsSize, ts.prices.length);
            assertEq(tsSize, ts.utilRates.length);
            assertEq(tsSize, ts.borrowRates.length);
            assertEq(tsSize, ts.indexRates.length);
        }
    }

    function testGetCandleBarsHiLo() public {
        uint8 len = 20;
        uint8 _maxLen = 10;

        uint256 utilRate0 = 1e18 / 100;
        uint256 borrowRate0 = 1e18 / 100;
        uint256 accFeeIndex0 = 1e18;
        uint256 lastPrice0 = 2 * 1e18;
        TestPoolViewer2(pool.viewer()).setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);

        pdq.setMaxLen(_maxLen);

        assertEq(0, pdq.size(_pool));

        for(uint256 i = 0; i < len; i++) {
            vm.roll(i*300); // 12 seconds
            vm.warp(i*3600);
            pdq.addPriceInfo(_pool);
            if(i % 2 == 0) {
                lastPrice0 = lastPrice0 + 1e18;
            } else if(i % 3 == 0){
                lastPrice0 = lastPrice0 - 2*1e18;
            }
            TestPoolViewer2(pool.viewer()).setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);
        }

        uint256 _len = len;
        if(_maxLen == 0) {
            _len = 0;
        }
        assertEq(_len, pdq.size(_pool));

        uint256 _frequency = 1;
        uint256 seriesLen = _maxLen;
        uint256 barsLen = (seriesLen/_frequency) + 2;
        IPriceDataQueries.TimeSeries memory ts = pdq.getCandleBars(_pool, _frequency);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        for(uint256 i = 0; i < ts.prices.length; i++) {
            assertEq(ts.prices[i].open,ts.prices[i].close);
            assertEq(ts.prices[i].high,ts.prices[i].low);
            assertEq(ts.prices[i].open,ts.prices[i].high);
            if(i < ts.prices.length - 2) {
                assertEq(ts.prices[i].open,ts.priceSeries[i].lastPrice);
                assertEq(ts.prices[i].timestamp,10*3600 + i * 3600);
            }
        }

        _frequency = 2;
        seriesLen = _maxLen;
        barsLen = (seriesLen/_frequency) + 2;
        IPriceDataQueries.TimeSeries memory ts1 = pdq.getCandleBars(_pool, _frequency);
        assertEq(seriesLen, ts1.priceSeries.length);
        assertEq(barsLen, ts1.prices.length);
        assertEq(barsLen, ts1.utilRates.length);
        assertEq(barsLen, ts1.borrowRates.length);
        assertEq(barsLen, ts1.indexRates.length);

        for(uint256 i = 0; i < ts1.prices.length; i++) {
            if(i < ts1.prices.length - 2) {
                assertEq(ts1.prices[i].open + 1e18,ts1.prices[i].close);
                assertEq(ts1.prices[i].high,ts1.prices[i].close);
                assertEq(ts1.prices[i].open,ts1.prices[i].low);
                assertEq(ts1.prices[i].timestamp,10*3600 + i * 2 * 3600);
            }
        }
    }

    function testGetCandleBarsLenGteMaxLen() public {
        uint256 utilRate0 = 1e18 / 100;
        uint256 borrowRate0 = 1e18 / 100;
        uint256 accFeeIndex0 = 1e18;
        uint256 lastPrice0 = 1e18;
        TestPoolViewer2(pool.viewer()).setLatestRates(utilRate0, borrowRate0, accFeeIndex0, lastPrice0);

        assertEq(0, pdq.size(_pool));
        pdq.addPriceInfo(_pool);
        assertEq(1, pdq.size(_pool));

        IPriceDataQueries.TimeSeries memory ts = pdq.getCandleBars(_pool, 1);
        for(uint256 i = 0; i < ts.prices.length; i++) {
            if(i < ts.prices.length - 2) {
                assertEq(ts.prices[i].timestamp,i * 3600);
            }
        }

        vm.roll(300); // 300 blocks is 1 hour
        vm.warp(3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(2, pdq.size(_pool));

        uint256 seriesLen = 2;
        uint256 barsLen = seriesLen + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 2;
        barsLen = (seriesLen/3) + 2;
        ts = pdq.getCandleBars(_pool, 3);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        pdq.setMaxLen(5);

        vm.roll(2*300); // 300 blocks is 1 hour
        vm.warp(2*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(3, pdq.size(_pool));

        vm.roll(3*300); // 300 blocks is 1 hour
        vm.warp(3*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(4, pdq.size(_pool));

        seriesLen = 4;
        barsLen = (seriesLen/1) + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 4;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        vm.roll(4*300); // 300 blocks is 1 hour
        vm.warp(4*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(5, pdq.size(_pool));

        seriesLen = 5;
        barsLen = (seriesLen/5) + 2;
        ts = pdq.getCandleBars(_pool, 5);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/1) + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        for(uint256 i = 0; i < ts.prices.length; i++) {
            if(i < ts.prices.length - 2) {
                assertEq(ts.prices[i].timestamp,i * 3600);
            }
        }

        seriesLen = 5;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        vm.roll(5*300); // 300 blocks is 1 hour
        vm.warp(5*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(6, pdq.size(_pool));

        seriesLen = 5;
        barsLen = (seriesLen/5) + 2;
        ts = pdq.getCandleBars(_pool, 5);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/1) + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        vm.roll(6*300); // 300 blocks is 1 hour
        vm.warp(6*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(7, pdq.size(_pool));

        seriesLen = 5;
        barsLen = (seriesLen/1) + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        vm.roll(7*300); // 300 blocks is 1 hour
        vm.warp(7*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(8, pdq.size(_pool));

        seriesLen = 5;
        barsLen = (seriesLen/1) + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        for(uint256 i = 0; i < ts.prices.length; i++) {
            if(i < ts.prices.length - 2) {
                assertEq(ts.prices[i].timestamp,3 * 3600 + i * 3600);
            }
        }

        seriesLen = 5;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        vm.roll(8*300); // 300 blocks is 1 hour
        vm.warp(8*3600); // 1 hour in seconds
        pdq.addPriceInfo(_pool);
        assertEq(9, pdq.size(_pool));

        seriesLen = 5;
        barsLen = (seriesLen/1) + 2;
        ts = pdq.getCandleBars(_pool, 1);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        for(uint256 i = 0; i < ts.prices.length; i++) {
            if(i < ts.prices.length - 2) {
                assertEq(ts.prices[i].timestamp,4 * 3600 + i * 3600);
            }
        }

        seriesLen = 5;
        barsLen = (seriesLen/2) + 2;
        ts = pdq.getCandleBars(_pool, 2);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/3) + 2;
        ts = pdq.getCandleBars(_pool, 3);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/4) + 2;
        ts = pdq.getCandleBars(_pool, 4);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);

        seriesLen = 5;
        barsLen = (seriesLen/5) + 2;
        ts = pdq.getCandleBars(_pool, 5);
        assertEq(seriesLen, ts.priceSeries.length);
        assertEq(barsLen, ts.prices.length);
        assertEq(barsLen, ts.utilRates.length);
        assertEq(barsLen, ts.borrowRates.length);
        assertEq(barsLen, ts.indexRates.length);
    }
}
