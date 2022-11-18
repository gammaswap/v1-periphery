import { ethers } from "hardhat";
import { expect } from "chai";

describe("PositionManager", function () {
    let TestERC20: any;
    let GammaPool: any;
    let GammaPoolFactory: any;
    let TestPositionManager: any;
    let factory: any;
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

        const implementation = await GammaPool.deploy();

        //address _feeToSetter, address _longStrategy, address _shortStrategy, address _protocol
        factory = await GammaPoolFactory.deploy(owner.address, addr1.address, addr2.address, addr3.address, implementation.address);

        // We can interact with the contract by calling `hardhatToken.method()`
        await tokenA.deployed();
        await tokenB.deployed();
        await factory.deployed();

        posMgr = await TestPositionManager.deploy(factory.address, WETH.address);

        await posMgr.deployed();

        const createPoolParams = {
            cfmm: cfmm.address,
            protocol: 1,
            tokens: [tokenA.address, tokenB.address]
        };

        const res = await (await factory.createPool2(createPoolParams)).wait();

        const { args } = res.events[1];
        gammaPoolAddr = args.pool;
        protocolId = args.protocolId;

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
                protocol: protocolId,
            }
            const tokens = [tokenA.address, tokenB.address];
            const amounts =  [10000, 10000];
            const payee = addr1.address;
            const data = ethers.utils.defaultAbiCoder.encode(["tuple(address payer, address cfmm, uint24 protocol)"],[sendTokensCallback]);
            
            const res = posMgr.sendTokensCallback(tokens, amounts, payee, data)
            
            await expect(res).to.be.revertedWith("Forbidden");
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
                protocol: protocolId,
            }

            const tokens = [tokenA.address, tokenB.address];
            const amounts =  [90000, 1000];
            const payee = addr1.address;
            const data = ethers.utils.defaultAbiCoder.encode(["tuple(address payer, address cfmm, uint24 protocol)"],[sendTokensCallback]);

            (await gammaPool.testSendTokensCallback(posMgr.address, tokens, amounts, payee, data)).wait();

            const newBalancePayer_A = await tokenA.balanceOf(owner.address);
            const newBalancePayer_B = await tokenB.balanceOf(owner.address);

            const newBalancePayee_A = await tokenA.balanceOf(addr1.address);
            const newBalancePayee_B = await tokenB.balanceOf(addr1.address);

            await expect(prevBalancePayer_A.toString()).to.not.be.equal(newBalancePayer_A.toString());
            await expect(prevBalancePayee_A.toString()).to.not.be.equal(newBalancePayee_A.toString());

            await expect(prevBalancePayer_B.toString()).to.not.be.equal(newBalancePayer_B.toString());
            await expect(prevBalancePayee_B.toString()).to.not.be.equal(newBalancePayee_B.toString());
        })


        it("#checkMinAmounts should revert when Amounts < AmountsMin", async function () {
            const amounts =  [90000, 1000];
            const amountsMin =  [90000, 1001];
            await expect(posMgr.testCheckAmountsMin(amounts, amountsMin)).to.be.revertedWith("AmountsMin");

            const amounts0 =  [90000, 1000];
            const amountsMin0 =  [90001, 1000];
            await expect(posMgr.testCheckAmountsMin(amounts0, amountsMin0)).to.be.revertedWith("AmountsMin");

            const amounts1 =  [90000, 1000];
            const amountsMin1 =  [90001, 1001];
            await expect(posMgr.testCheckAmountsMin(amounts1, amountsMin1)).to.be.revertedWith("AmountsMin");

            const amounts2 =  [1, 1];
            const amountsMin2 =  [1, 2];
            await expect(posMgr.testCheckAmountsMin(amounts2, amountsMin2)).to.be.revertedWith("AmountsMin");

            const amounts3 =  [0, 1];
            const amountsMin3 =  [1, 1];
            await expect(posMgr.testCheckAmountsMin(amounts3, amountsMin3)).to.be.revertedWith("AmountsMin");

            const amounts4 =  [1, 0];
            const amountsMin4 =  [1, 1];
            await expect(posMgr.testCheckAmountsMin(amounts4, amountsMin4)).to.be.revertedWith("AmountsMin");

            const amounts5 =  [0, 0];
            const amountsMin5 =  [1, 1];
            await expect(posMgr.testCheckAmountsMin(amounts5, amountsMin5)).to.be.revertedWith("AmountsMin");
        });

        it("#checkMinAmounts should not revert when Amounts >= AmountsMin", async function () {
            const amounts =  [90000, 1000];
            const amountsMin =  [90000, 1000];
            posMgr.testCheckAmountsMin(amounts, amountsMin);

            const amounts0 =  [90001, 1000];
            const amountsMin0 =  [90000, 1000];
            posMgr.testCheckAmountsMin(amounts0, amountsMin0);

            const amounts1 =  [90000, 1001];
            const amountsMin1 =  [90000, 1000];
            posMgr.testCheckAmountsMin(amounts1, amountsMin1);

            const amounts2 =  [90001, 1001];
            const amountsMin2 =  [90000, 1000];
            posMgr.testCheckAmountsMin(amounts2, amountsMin2);

            const amounts3 =  [1, 1];
            const amountsMin3 =  [1, 1];
            posMgr.testCheckAmountsMin(amounts3, amountsMin3);

            const amounts4 =  [1, 1];
            const amountsMin4 =  [0, 0];
            posMgr.testCheckAmountsMin(amounts4, amountsMin4);

            const amounts5 =  [0, 0];
            const amountsMin5 =  [0, 0];
            posMgr.testCheckAmountsMin(amounts5, amountsMin5);
        });
    });

    // You can nest describe calls to create subsections.
    describe("Short Gamma Functions", function () {
        it("#depositNoPull should return shares", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const DepositWithdrawParams =  {
                cfmm: cfmm.address,
                protocol: protocolId,
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
                protocol: protocolId,
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
                protocol: protocolId,
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
                protocol: protocolId,
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
                protocol: protocolId,
                tokenId: tokenId,
                lpTokens: 1,
                to: owner.address,
                minBorrowed: [0,0],
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
                protocol: protocolId,
                tokenId: tokenId,
                liquidity: 1,
                to: owner.address,
                minRepaid: [0,0],
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.repayLiquidity(RepayLiquidityParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.liquidityPaid.toNumber()).to.equal(24);
            expect(args.amountsLen.toNumber()).to.equal(2);
        });

        it("#increaseCollateral should return tokenId and length of tokens held", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const AddRemoveCollateralParams = {
                cfmm: cfmm.address,
                protocol: protocolId,
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
                protocol: protocolId,
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
                protocol: protocolId,
                tokenId: tokenId,
                deltas: [4, 2],
                liquidity: 1,
                to: owner.address,
                minCollateral: [0,0],
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.rebalanceCollateral(RebalanceCollateralParams)).wait();
            
            const { args } = res.events[0]
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeldLen.toNumber()).to.equal(2);
        });
    });
});
