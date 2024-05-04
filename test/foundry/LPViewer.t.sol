pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/test/TestGammaPool3.sol";
import "../../contracts/lens/LPViewer.sol";

contract LPViewerTest is Test {

    TestGammaPool3 pool0;
    TestGammaPool3 pool1;
    TestGammaPool3 pool2;
    TestGammaPool3 pool3;
    TestGammaPool3 pool4;
    TERC20 tokenA;
    TERC20 tokenB;
    TERC20 tokenC;
    TERC20 tokenD;
    TERC20 tokenE;

    address addr1;
    address addr2;
    address addr3;
    address addr4;

    LPViewer lpViewer;

    function setUp() public {
        addr1 = vm.addr(1);
        addr2 = vm.addr(2);
        addr3 = vm.addr(3);
        addr4 = vm.addr(4);

        lpViewer = new LPViewer(addr1);
        tokenA = new TERC20("TokenA", "TOKA");
        tokenB = new TERC20("TokenB", "TOKB");
        tokenC = new TERC20("TokenC", "TOKC");
        tokenD = new TERC20("TokenD", "TOKD");
        tokenE = new TERC20("TokenE", "TOKE");
        pool0 = createPool(1, address(tokenA), address(tokenB));
        pool1 = createPool(2, address(tokenA), address(tokenC));
        pool2 = createPool(3, address(tokenB), address(tokenC));
        pool3 = createPool(4, address(tokenB), address(tokenD));
        pool4 = createPool(5, address(tokenA), address(tokenE));


        pool0.mintTo(addr1, 100*1e18);
        pool1.mintTo(addr1, 200*1e18);
        pool2.mintTo(addr1, 300*1e18);

        pool1.mintTo(addr2, 200*1e18);
        pool3.mintTo(addr2, 400*1e18);
        pool4.mintTo(addr2, 500*1e18);

        pool0.mintTo(addr3, 100*1e18);
        pool4.mintTo(addr3, 200*1e18);
    }

    function createPool(uint16 protocolId, address token0, address token1) internal returns(TestGammaPool3 pool) {
        pool = new TestGammaPool3(protocolId, address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0));
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;
        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;
        pool.initialize(address(666), tokens, decimals, 0, "0x");
    }

    function testTotalSupplies() public {
        assertEq(pool0.totalSupply(),200 * 1e18);
        assertEq(pool1.totalSupply(),400 * 1e18);
        assertEq(pool2.totalSupply(),300 * 1e18);
        assertEq(pool3.totalSupply(),400 * 1e18);
        assertEq(pool4.totalSupply(),700 * 1e18);
    }

    function testAddr1() public {
        (address token0, address token1, uint256 token0Balance, uint256 token1Balance, uint256 lpBalance) =
        lpViewer.lpBalanceByPool(addr1, address(pool0));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenB));
        assertEq(token0Balance, 250*1e18);
        assertEq(token1Balance, 25000*1e18);
        assertEq(lpBalance, 100*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr1, address(pool1));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, uint256(200*500*1e18)/400);
        assertEq(token1Balance, uint256(200*50000*1e18)/400);
        assertEq(lpBalance, 200*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr1, address(pool2));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, uint256(300*500*1e18)/300);
        assertEq(token1Balance, uint256(300*50000*1e18)/300);
        assertEq(lpBalance, 300*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr1, address(pool3));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenD));
        assertEq(token0Balance, uint256(0*500*1e18)/300);
        assertEq(token1Balance, uint256(0*50000*1e18)/300);
        assertEq(lpBalance, 0*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr1, address(pool4));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenE));
        assertEq(token0Balance, uint256(0*500*1e18)/300);
        assertEq(token1Balance, uint256(0*50000*1e18)/300);
        assertEq(lpBalance, 0*1e18);
    }

    function testAddr1Pools() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory token0, address[] memory token1, uint256[] memory token0Balance, uint256[] memory token1Balance,
        uint256[] memory lpBalance) = lpViewer.lpBalanceByPools(addr1, pools);

        uint256[] memory lpBalances = new uint256[](5);
        lpBalances[0] = 100 * 1e18;
        lpBalances[1] = 200 * 1e18;
        lpBalances[2] = 300 * 1e18;
        uint256[] memory token0Balances = new uint256[](5);
        token0Balances[0] = 250 * 1e18;
        token0Balances[1] = uint256(200*500*1e18)/400;
        token0Balances[2] = uint256(300*500*1e18)/300;
        uint256[] memory token1Balances = new uint256[](5);
        token1Balances[0] = 25000 * 1e18;
        token1Balances[1] = uint256(200*50000*1e18)/400;
        token1Balances[2] = uint256(300*50000*1e18)/300;

        for(uint256 i; i < 5; i++) {
            address[] memory tokens = TestGammaPool3(pools[i]).tokens();
            assertEq(token0[i], tokens[0]);
            assertEq(token1[i], tokens[1]);
            assertEq(lpBalance[i], lpBalances[i]);
            assertEq(token0Balance[i], token0Balances[i]);
            assertEq(token1Balance[i], token1Balances[i]);
        }
    }

    function testAddr1TokenBalances() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory tokens, uint256[] memory tokenBalances, uint256 size) = lpViewer.tokenBalancesInPools(addr1, pools);

        assertEq(size, 5);

        address[] memory expectedTokens = new address[](5);
        expectedTokens[0] = address(tokenA);
        expectedTokens[1] = address(tokenB);
        expectedTokens[2] = address(tokenC);
        expectedTokens[3] = address(tokenD);
        expectedTokens[4] = address(tokenE);
        uint256[] memory expectedBalances = new uint256[](5);
        expectedBalances[0] = 250 * 1e18 + uint256(200*500*1e18)/400;
        expectedBalances[1] = 25000 * 1e18 + uint256(300*500*1e18)/300;
        expectedBalances[2] = uint256(200*50000*1e18)/400 + uint256(300*50000*1e18)/300;

        for(uint256 i; i < size; i++) {
            assertEq(tokens[i], expectedTokens[i]);
            assertEq(tokenBalances[i], expectedBalances[i]);
        }

        (address[] memory _tokens, uint256[] memory _tokenBalances, uint256 _size) = lpViewer.tokenBalancesInPoolsNonStatic(addr1, pools);

        assertEq(_size, size);

        for(uint256 i; i < size; i++) {
            assertEq(_tokens[i], expectedTokens[i]);
            assertEq(_tokenBalances[i], expectedBalances[i]);
        }
    }

    function testAddr2() public {
        (address token0, address token1, uint256 token0Balance, uint256 token1Balance, uint256 lpBalance) =
        lpViewer.lpBalanceByPool(addr2, address(pool0));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenB));
        assertEq(token0Balance, 0*1e18);
        assertEq(token1Balance, 0*1e18);
        assertEq(lpBalance, 0*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr2, address(pool1));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, uint256(200*500*1e18)/400);
        assertEq(token1Balance, uint256(200*50000*1e18)/400);
        assertEq(lpBalance, 200*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr2, address(pool2));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, uint256(0*500*1e18)/400);
        assertEq(token1Balance, uint256(0*50000*1e18)/400);
        assertEq(lpBalance, 0*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr2, address(pool3));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenD));
        assertEq(token0Balance, uint256(400*500*1e18)/400);
        assertEq(token1Balance, uint256(400*50000*1e18)/400);
        assertEq(lpBalance, 400*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr2, address(pool4));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenE));
        assertEq(token0Balance, uint256(500*500*1e18)/700);
        assertEq(token1Balance, uint256(500*50000*1e18)/700);
        assertEq(lpBalance, 500*1e18);
    }

    function testAddr2Pools() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory token0, address[] memory token1, uint256[] memory token0Balance, uint256[] memory token1Balance,
        uint256[] memory lpBalance) = lpViewer.lpBalanceByPools(addr2, pools);

        uint256[] memory lpBalances = new uint256[](5);
        lpBalances[1] = 200 * 1e18;
        lpBalances[3] = 400 * 1e18;
        lpBalances[4] = 500 * 1e18;
        uint256[] memory token0Balances = new uint256[](5);
        token0Balances[1] = uint256(200*500*1e18)/400;
        token0Balances[3] = uint256(400*500*1e18)/400;
        token0Balances[4] = uint256(500*500*1e18)/700;
        uint256[] memory token1Balances = new uint256[](5);
        token1Balances[1] = uint256(200*50000*1e18)/400;
        token1Balances[3] = uint256(400*50000*1e18)/400;
        token1Balances[4] = uint256(500*50000*1e18)/700;

        for(uint256 i; i < 5; i++) {
            address[] memory tokens = TestGammaPool3(pools[i]).tokens();
            assertEq(token0[i], tokens[0]);
            assertEq(token1[i], tokens[1]);
            assertEq(lpBalance[i], lpBalances[i]);
            assertEq(token0Balance[i], token0Balances[i]);
            assertEq(token1Balance[i], token1Balances[i]);
        }
    }

    function testAddr2TokenBalances() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory tokens, uint256[] memory tokenBalances, uint256 size) = lpViewer.tokenBalancesInPools(addr2, pools);

        assertEq(size, 5);

        address[] memory expectedTokens = new address[](5);
        expectedTokens[0] = address(tokenA);
        expectedTokens[1] = address(tokenB);
        expectedTokens[2] = address(tokenC);
        expectedTokens[3] = address(tokenD);
        expectedTokens[4] = address(tokenE);
        uint256[] memory expectedBalances = new uint256[](5);
        expectedBalances[0] = uint256(200*500*1e18)/400 + uint256(500*500*1e18)/700;
        expectedBalances[1] = uint256(400*500*1e18)/400;
        expectedBalances[2] = uint256(200*50000*1e18)/400;
        expectedBalances[3] = uint256(400*50000*1e18)/400;
        expectedBalances[4] = uint256(500*50000*1e18)/700;

        for(uint256 i; i < size; i++) {
            assertEq(tokens[i], expectedTokens[i]);
            assertEq(tokenBalances[i], expectedBalances[i]);
        }

        (address[] memory _tokens, uint256[] memory _tokenBalances, uint256 _size) = lpViewer.tokenBalancesInPoolsNonStatic(addr2, pools);

        assertEq(_size, size);

        for(uint256 i; i < size; i++) {
            assertEq(_tokens[i], expectedTokens[i]);
            assertEq(_tokenBalances[i], expectedBalances[i]);
        }
    }

    function testAddr3() public {
        (address token0, address token1, uint256 token0Balance, uint256 token1Balance, uint256 lpBalance) =
            lpViewer.lpBalanceByPool(addr3, address(pool0));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenB));
        assertEq(token0Balance, 250*1e18);
        assertEq(token1Balance, 25000*1e18);
        assertEq(lpBalance, 100*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr3, address(pool1));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, 0);
        assertEq(token1Balance, 0);
        assertEq(lpBalance, 0);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr3, address(pool2));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, 0);
        assertEq(token1Balance, 0);
        assertEq(lpBalance, 0);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr3, address(pool3));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenD));
        assertEq(token0Balance, 0);
        assertEq(token1Balance, 0);
        assertEq(lpBalance, 0);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr3, address(pool4));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenE));
        assertEq(token0Balance, uint256(200*500*1e18)/700);
        assertEq(token1Balance, uint256(200*50000*1e18)/700);
        assertEq(lpBalance, 200*1e18);
    }

    function testAddr3Pools() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory token0, address[] memory token1, uint256[] memory token0Balance, uint256[] memory token1Balance,
        uint256[] memory lpBalance) = lpViewer.lpBalanceByPools(addr3, pools);

        uint256[] memory lpBalances = new uint256[](5);
        lpBalances[0] = 100 * 1e18;
        lpBalances[4] = 200 * 1e18;
        uint256[] memory token0Balances = new uint256[](5);
        token0Balances[0] = uint256(100*500*1e18)/200;
        token0Balances[4] = uint256(200*500*1e18)/700;
        uint256[] memory token1Balances = new uint256[](5);
        token1Balances[0] = uint256(100*50000*1e18)/200;
        token1Balances[4] = uint256(200*50000*1e18)/700;

        for(uint256 i; i < 5; i++) {
            address[] memory tokens = TestGammaPool3(pools[i]).tokens();
            assertEq(token0[i], tokens[0]);
            assertEq(token1[i], tokens[1]);
            assertEq(lpBalance[i], lpBalances[i]);
            assertEq(token0Balance[i], token0Balances[i]);
            assertEq(token1Balance[i], token1Balances[i]);
        }
    }

    function testAddr3TokenBalances() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory tokens, uint256[] memory tokenBalances, uint256 size) = lpViewer.tokenBalancesInPools(addr3, pools);

        assertEq(size, 5);

        address[] memory expectedTokens = new address[](5);
        expectedTokens[0] = address(tokenA);
        expectedTokens[1] = address(tokenB);
        expectedTokens[2] = address(tokenC);
        expectedTokens[3] = address(tokenD);
        expectedTokens[4] = address(tokenE);
        uint256[] memory expectedBalances = new uint256[](5);
        expectedBalances[0] = uint256(100*500*1e18)/200 + uint256(200*500*1e18)/700;
        expectedBalances[1] = uint256(100*50000*1e18)/200;
        expectedBalances[4] = uint256(200*50000*1e18)/700;

        for(uint256 i; i < size; i++) {
            assertEq(tokens[i], expectedTokens[i]);
            assertEq(tokenBalances[i], expectedBalances[i]);
        }

        (address[] memory _tokens, uint256[] memory _tokenBalances, uint256 _size) = lpViewer.tokenBalancesInPoolsNonStatic(addr3, pools);

        assertEq(_size, size);

        for(uint256 i; i < size; i++) {
            assertEq(_tokens[i], expectedTokens[i]);
            assertEq(_tokenBalances[i], expectedBalances[i]);
        }
    }

    function testAddr4() public {
        (address token0, address token1, uint256 token0Balance, uint256 token1Balance, uint256 lpBalance) =
        lpViewer.lpBalanceByPool(addr4, address(pool0));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenB));
        assertEq(token0Balance, 0*1e18);
        assertEq(token1Balance, 0*1e18);
        assertEq(lpBalance, 0*1e18);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr4, address(pool1));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, 0);
        assertEq(token1Balance, 0);
        assertEq(lpBalance, 0);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr4, address(pool2));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenC));
        assertEq(token0Balance, 0);
        assertEq(token1Balance, 0);
        assertEq(lpBalance, 0);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr4, address(pool3));// has liquidity in this pool
        assertEq(token0, address(tokenB));
        assertEq(token1, address(tokenD));
        assertEq(token0Balance, 0);
        assertEq(token1Balance, 0);
        assertEq(lpBalance, 0);

        (token0, token1, token0Balance, token1Balance, lpBalance) =
        lpViewer.lpBalanceByPool(addr4, address(pool4));// has liquidity in this pool
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenE));
        assertEq(token0Balance, uint256(0*500*1e18)/700);
        assertEq(token1Balance, uint256(0*50000*1e18)/700);
        assertEq(lpBalance, 0*1e18);
    }

    function testAddr4Pools() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory token0, address[] memory token1, uint256[] memory token0Balance, uint256[] memory token1Balance,
        uint256[] memory lpBalance) = lpViewer.lpBalanceByPools(addr4, pools);

        uint256[] memory lpBalances = new uint256[](5);
        uint256[] memory token0Balances = new uint256[](5);
        uint256[] memory token1Balances = new uint256[](5);

        for(uint256 i; i < 5; i++) {
            address[] memory tokens = TestGammaPool3(pools[i]).tokens();
            assertEq(token0[i], tokens[0]);
            assertEq(token1[i], tokens[1]);
            assertEq(lpBalance[i], lpBalances[i]);
            assertEq(token0Balance[i], token0Balances[i]);
            assertEq(token1Balance[i], token1Balances[i]);
        }
    }

    function testAddr4TokenBalances() public {
        address[] memory pools = new address[](5);
        pools[0] = address(pool0);
        pools[1] = address(pool1);
        pools[2] = address(pool2);
        pools[3] = address(pool3);
        pools[4] = address(pool4);

        (address[] memory tokens, uint256[] memory tokenBalances, uint256 size) = lpViewer.tokenBalancesInPools(addr4, pools);

        assertEq(size, 5);

        address[] memory expectedTokens = new address[](5);
        expectedTokens[0] = address(tokenA);
        expectedTokens[1] = address(tokenB);
        expectedTokens[2] = address(tokenC);
        expectedTokens[3] = address(tokenD);
        expectedTokens[4] = address(tokenE);
        uint256[] memory expectedBalances = new uint256[](5);

        for(uint256 i; i < size; i++) {
            assertEq(tokens[i], expectedTokens[i]);
            assertEq(tokenBalances[i], expectedBalances[i]);
        }

        (address[] memory _tokens, uint256[] memory _tokenBalances, uint256 _size) = lpViewer.tokenBalancesInPoolsNonStatic(addr4, pools);

        assertEq(_size, size);

        for(uint256 i; i < size; i++) {
            assertEq(_tokens[i], expectedTokens[i]);
            assertEq(_tokenBalances[i], expectedBalances[i]);
        }
    }
}