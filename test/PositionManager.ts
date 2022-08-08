import { ethers } from "hardhat";
import { expect } from "chai";

describe("GammaPoolFactory", function () {
    let TestERC20: any;
    let TestPoolAddress: any;
    let GammaPool: any;
    let GammaPoolFactory: any;
    let TestPositionManager: any;
    let factory: any;
    let testPoolAddress: any;
    let tokenA: any;
    let tokenB: any;
    let WETH: any;
    let owner: any;
    let addr1: any;
    let addr2: any;
    let addr3: any;
    let addr4: any;
    let posMgr: any;
    let gammaPool: any;
    let cfmm: any;
    let protocolId: any;
    let protocol: any;
    let count: any;
    let gammaPoolAddr: any;
    let tokenId: any;

    // `beforeEach` will run before each test, re-deploying the contract every
    // time. It receives a callback, which can be async.
    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        TestERC20 = await ethers.getContractFactory("TestERC20");
        GammaPoolFactory = await ethers.getContractFactory("TestGammaPoolFactory");
        TestPositionManager = await ethers.getContractFactory("TestPositionManager");
        GammaPool = await ethers.getContractFactory("TestGammaPool");
        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

        // To deploy our contract, we just have to call Token.deploy() and await
        // for it to be deployed(), which happens onces its transaction has been
        // mined.
        tokenA = await TestERC20.deploy("Test Token A", "TOKA");
        tokenB = await TestERC20.deploy("Test Token B", "TOKB");
        cfmm = await TestERC20.deploy("CFMM LP Token", "LP_CFMM");
        WETH = await TestERC20.deploy("WETH", "WETH");
        //address _feeToSetter, address _longStrategy, address _shortStrategy, address _protocol
        factory = await GammaPoolFactory.deploy(owner.address, addr1.address, addr2.address, addr3.address);

        // We can interact with the contract by calling `hardhatToken.method()`
        await tokenA.deployed();
        await tokenB.deployed();
        await factory.deployed();

        const COMPUTED_INIT_CODE_HASH = ethers.utils.keccak256(
            GammaPool.bytecode
        );

        //address _factory, address _WETH, bytes32 _initCodeHash
        posMgr = await TestPositionManager.deploy(factory.address, WETH.address, COMPUTED_INIT_CODE_HASH);

        await posMgr.deployed();

        const createPoolParams = {
            cfmm: cfmm.address,
            protocol: 1,
            tokens: [tokenA.address, tokenB.address]
        };

        const res = await (await factory.createPool(createPoolParams)).wait();

        const { args } = res.events[1];
        gammaPoolAddr = args.pool;
        let _cfmm = args.cfmm;
        protocolId = args.protocolId;
        protocol = args.protocol;
        count = args.count.toString();

        gammaPool = await GammaPool.attach(
            gammaPoolAddr // The deployed contract address
        );
        await gammaPool.approve(posMgr.address, ethers.constants.MaxUint256);
        
        const { events } = await (await posMgr.createTestLoan(owner.address)).wait();
        tokenId = events[0].args.tokenId;
        
    });

    describe("Base Functions", function () {
        it("#sendTokensCallback should revert with FORBIDDEN when calling outside Gamma Pool", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const sendTokensCallback =  {
                payer: owner.address,
                cfmm: cfmm.address,
                protocol: 1,
            }
            const tokens = [tokenA.address, tokenB.address];
            const amounts =  [10000, 10000];
            const payee = addr1.address;
            const data = ethers.utils.defaultAbiCoder.encode(["tuple(address payer, address cfmm, uint24 protocol)"],[sendTokensCallback]);
            
            const res = posMgr.sendTokensCallback(tokens, amounts, payee, data)
            
            await expect(res).to.be.revertedWith("FORBIDDEN");
        })

        it("#sendTokensCallback should change balances of tokens", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const prevBalancePayer_A = await tokenA.balanceOf(owner.address);
            const prevBalancePayer_B = await tokenB.balanceOf(owner.address);
            
            const prevBalancePayee_A = await tokenA.balanceOf(addr1.address);
            const prevBalancePayee_B = await tokenB.balanceOf(addr1.address);

            const sendTokensCallback =  {
                payer: owner.address,
                cfmm: cfmm.address,
                protocol: 1,
            }
            const tokens = [tokenA.address, tokenB.address];
            const amounts =  [90000, 1000];
            const payee = addr1.address;
            const data = ethers.utils.defaultAbiCoder.encode(["tuple(address payer, address cfmm, uint24 protocol)"],[sendTokensCallback]);
            
            const res = await gammaPool.testSendTokensCallback(posMgr.address, tokens, amounts, payee, data)

            const newBalancePayer_A = await tokenA.balanceOf(owner.address);
            const newBalancePayer_B = await tokenB.balanceOf(owner.address);
            
            const newBalancePayee_A = await tokenA.balanceOf(addr1.address);
            const newBalancePayee_B = await tokenB.balanceOf(addr1.address);
                        
            await expect(prevBalancePayer_A.toString()).to.not.be.equal(newBalancePayer_A.toString());
            await expect(prevBalancePayee_A.toString()).to.not.be.equal(newBalancePayee_A.toString());

            await expect(prevBalancePayer_B.toString()).to.not.be.equal(newBalancePayer_B.toString());
            await expect(prevBalancePayee_B.toString()).to.not.be.equal(newBalancePayee_B.toString());
        })
    });

    // You can nest describe calls to create subsections.
    describe("Short Gamma Functions", function () {
        it("#depositNoPull should return shares", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const DepositWithdrawParams =  {
                cfmm: cfmm.address,
                protocol: 1,
                lpTokens: 1,
                to: addr4.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.depositNoPull(DepositWithdrawParams)).wait();
            
            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.shares.toNumber()).to.equal(15);
        });

        it("#withdrawNoPull should return assets", async function () {
            const DepositWithdrawParams =  {
                cfmm: cfmm.address,
                protocol: 1,
                lpTokens: 1,
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }

            const res = await (await posMgr.withdrawNoPull(DepositWithdrawParams)).wait();
            
            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.assets.toNumber()).to.equal(16);
        });

        it("#depositReserves should return shares and length of reserves", async function () {
            const DepositReservesParams =  {
                cfmm: cfmm.address,
                amountsDesired: [10000, 100],
                amountsMin: [1000, 10],
                to: addr4.address,
                protocol: 1,
                deadline: ethers.constants.MaxUint256
            }
            const res = await (await posMgr.depositReserves(DepositReservesParams)).wait();
            
            const { args } = res.events[0];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.reservesLen).to.equal(4);
            expect(args.shares.toNumber()).to.equal(18);
        });

        it("#withdrawReserves should return assets and lenght of reserves", async function () {            
            const WithdrawReservesParams =  {
                cfmm: cfmm.address,
                protocol: 1,
                amount: 1000,
                amountsMin: [100, 200, 300],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }

            const res = await (await posMgr.withdrawReserves(WithdrawReservesParams)).wait();

            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.reservesLen).to.equal(3);
            expect(args.assets.toNumber()).to.equal(17);
        });
    });

    // You can nest describe calls to create subsections.
    describe("Long Gamma Functions", function () {
        it("#createLoan should return tokenId", async function () {
            const res = await (await posMgr.createLoan(cfmm.address, 1, owner.address, ethers.constants.MaxUint256)).wait();
            
            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
        });

        it("#borrowLiquidity should return tokenId", async function () {
            const BorrowLiquidityParams = {
                cfmm: cfmm.address,
                protocol: 1,
                tokenId: tokenId,
                lpTokens: 1,
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.borrowLiquidity(BorrowLiquidityParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
        });

        it("#repayLiquidity should return tokenId, paid liquidity, paid lp tokens and length of amounts array", async function () {
            const RepayLiquidityParams = {
                cfmm: cfmm.address,
                protocol: 1,
                tokenId: tokenId,
                liquidity: 1,
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.repayLiquidity(RepayLiquidityParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.liquidityPaid.toNumber()).to.equal(24);
            expect(args.lpTokensPaid.toNumber()).to.equal(25);
            expect(args.amountsLen.toNumber()).to.equal(9);
        });

        it("#increaseCollateral should return tokenId and length of tokens held", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const AddRemoveCollateralParams = {
                cfmm: cfmm.address,
                protocol: 1,
                tokenId: tokenId,
                amounts: [100,10],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.increaseCollateral(AddRemoveCollateralParams)).wait();
            
            const { args } = res.events[2];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeldLen.toNumber()).to.equal(6);
        });

        it("#decreaseCollateral should return tokenId and length of tokens held", async function () {
            const AddRemoveCollateralParams = {
                cfmm: cfmm.address,
                protocol: 1,
                tokenId: tokenId,
                amounts: [100,10],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.decreaseCollateral(AddRemoveCollateralParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeldLen.toNumber()).to.equal(7);
        });

        it("#rebalanceCollateral should return tokenId and length of tokens held", async function () {            
            const RebalanceCollateralParams = {
                cfmm: cfmm.address,
                protocol: 1,
                tokenId: tokenId,
                deltas: [4, 2],
                liquidity: 1,
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.rebalanceCollateral(RebalanceCollateralParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeldLen.toNumber()).to.equal(10);
        });

        it("#rebalanceCollateralWithLiquidity should return tokenId and length of tokens held", async function () {
            const RebalanceCollateralParams = {
                cfmm: cfmm.address,
                protocol: 1,
                tokenId: tokenId,
                deltas: [4, 2],
                liquidity: 2,
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.rebalanceCollateralWithLiquidity(RebalanceCollateralParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeldLen.toNumber()).to.equal(11);
        });
    });
});
