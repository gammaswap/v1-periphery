import { ethers } from "hardhat";
import { expect } from "chai";

describe("PositionManager", function () {
    let TestERC20: any;
    let GammaPool: any;
    let GammaPool2: any;
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
    let gammaPool2: any;
    let gammaPool3: any;
    let gammaPool4: any;
    let cfmm: any;
    let cfmm2: any;
    let cfmm3: any;
    let protocolId: any;
    let gammaPoolAddr: any;
    let gammaPoolAddr2: any;
    let gammaPoolAddr3: any;
    let gammaPoolAddr4: any;
    let tokenId: any;

    // `beforeEach` will run before each test, re-deploying the contract every
    // time. It receives a callback, which can be async.
    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        TestERC20 = await ethers.getContractFactory("TestERC20");
        GammaPoolFactory = await ethers.getContractFactory("TestGammaPoolFactory");
        TestPositionManager = await ethers.getContractFactory("TestPositionManager");
        GammaPool = await ethers.getContractFactory("TestGammaPool");
        GammaPool2 = await ethers.getContractFactory("TestGammaPool2");
        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

        // To deploy our contract, we just have to call Token.deploy() and await
        // for it to be deployed(), which happens onces its transaction has been
        // mined.
        tokenA = await TestERC20.deploy("Test Token A", "TOKA");
        tokenB = await TestERC20.deploy("Test Token B", "TOKB");
        cfmm = await TestERC20.deploy("CFMM LP Token", "LP_CFMM");
        cfmm2 = await TestERC20.deploy("CFMM2 LP Token", "LP_CFMM2");
        cfmm3 = await TestERC20.deploy("CFMM3 LP Token", "LP_CFMM3");
        WETH = await TestERC20.deploy("WETH", "WETH");

        factory = await GammaPoolFactory.deploy(owner.address);

        const implementation = await GammaPool.deploy(1, factory.address, addr1.address, addr2.address, addr3.address);

        await (await factory.addProtocol(implementation.address)).wait();

        posMgr = await TestPositionManager.deploy(factory.address, WETH.address);

        const createPoolParams = {
            cfmm: cfmm.address,
            protocolId: 1,
            tokens: [tokenA.address, tokenB.address]
        };

        const data = ethers.utils.defaultAbiCoder.encode(
            [],
            []
        );
        const res = await (await factory.createPool(createPoolParams.protocolId, createPoolParams.cfmm ,createPoolParams.tokens, data)).wait();
        const res2 = await (await factory.createPool(createPoolParams.protocolId, cfmm2.address ,createPoolParams.tokens, data)).wait();
        const res3 = await (await factory.createPool(createPoolParams.protocolId, cfmm3.address ,createPoolParams.tokens, data)).wait();

        const { args } = res.events[1];
        gammaPoolAddr = args.pool;

        gammaPoolAddr2 = res2.events[1].args.pool;
        gammaPoolAddr3 = res3.events[1].args.pool;

        protocolId = args.protocolId;

        gammaPool = await GammaPool.attach(
            gammaPoolAddr // The deployed contract address
        );
        await gammaPool.approve(posMgr.address, ethers.constants.MaxUint256);

        gammaPool2 = await GammaPool.attach(
            gammaPoolAddr2 // The deployed contract address
        );
        await gammaPool2.approve(posMgr.address, ethers.constants.MaxUint256);

        gammaPool3 = await GammaPool.attach(
            gammaPoolAddr3 // The deployed contract address
        );
        await gammaPool3.approve(posMgr.address, ethers.constants.MaxUint256);

        const { events } = await (await posMgr.createTestLoan(owner.address)).wait();
        tokenId = events[0].args.tokenId;
    });

    describe("Base Functions", function () {
        it("deployment", async function() {
            expect(await posMgr.name()).to.be.equal("PositionManager");
            expect(await posMgr.symbol()).to.be.equal("PM-V1");
            expect(await posMgr.factory()).to.be.equal(factory.address);
            expect(await posMgr.WETH()).to.be.equal(WETH.address);
        })

        it("#sendTokensCallback should revert with NotGammaPool when calling outside Gamma Pool", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const sendTokensCallback = {
                payer: owner.address,
                cfmm: cfmm.address,
                protocol: protocolId,
            }
            const tokens = [tokenA.address, tokenB.address];
            const amounts =  [10000, 10000];
            const payee = addr1.address;
            const data = ethers.utils.defaultAbiCoder.encode(["tuple(address payer, address cfmm, uint24 protocol)"],[sendTokensCallback]);
            
            const res = posMgr.sendTokensCallback(tokens, amounts, payee, data)
            
            await expect(res).to.be.revertedWith("NotGammaPool");
        })

        it("#sendTokensCallback should change balances of tokens", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const prevBalancePayer_A = await tokenA.balanceOf(owner.address);
            const prevBalancePayer_B = await tokenB.balanceOf(owner.address);
            
            const prevBalancePayee_A = await tokenA.balanceOf(addr1.address);
            const prevBalancePayee_B = await tokenB.balanceOf(addr1.address);

            const sendTokensCallback = {
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

        it("#checkMinReserves should revert when Amounts < AmountsMin", async function () {
            const amounts =  [90000, 1000];
            const amountsMin =  [90000, 1001];
            await expect(posMgr.testCheckMinReserves(amounts, amountsMin)).to.be.revertedWith("AmountsMin");

            const amounts0 =  [90000, 1000];
            const amountsMin0 =  [90001, 1000];
            await expect(posMgr.testCheckMinReserves(amounts0, amountsMin0)).to.be.revertedWith("AmountsMin");

            const amounts1 =  [90000, 1000];
            const amountsMin1 =  [90001, 1001];
            await expect(posMgr.testCheckMinReserves(amounts1, amountsMin1)).to.be.revertedWith("AmountsMin");

            const amounts2 =  [1, 1];
            const amountsMin2 =  [1, 2];
            await expect(posMgr.testCheckMinReserves(amounts2, amountsMin2)).to.be.revertedWith("AmountsMin");

            const amounts3 =  [0, 1];
            const amountsMin3 =  [1, 1];
            await expect(posMgr.testCheckMinReserves(amounts3, amountsMin3)).to.be.revertedWith("AmountsMin");

            const amounts4 =  [1, 0];
            const amountsMin4 =  [1, 1];
            await expect(posMgr.testCheckMinReserves(amounts4, amountsMin4)).to.be.revertedWith("AmountsMin");

            const amounts5 =  [0, 0];
            const amountsMin5 =  [1, 1];
            await expect(posMgr.testCheckMinReserves(amounts5, amountsMin5)).to.be.revertedWith("AmountsMin");
        });

        it("#checkMinReserves should not revert when Amounts >= AmountsMin", async function () {
            const amounts =  [90000, 1000];
            const amountsMin =  [90000, 1000];
            posMgr.testCheckMinReserves(amounts, amountsMin);

            const amounts0 =  [90001, 1000];
            const amountsMin0 =  [90000, 1000];
            posMgr.testCheckMinReserves(amounts0, amountsMin0);

            const amounts1 =  [90000, 1001];
            const amountsMin1 =  [90000, 1000];
            posMgr.testCheckMinReserves(amounts1, amountsMin1);

            const amounts2 =  [90001, 1001];
            const amountsMin2 =  [90000, 1000];
            posMgr.testCheckMinReserves(amounts2, amountsMin2);

            const amounts3 =  [1, 1];
            const amountsMin3 =  [1, 1];
            posMgr.testCheckMinReserves(amounts3, amountsMin3);

            const amounts4 =  [1, 1];
            const amountsMin4 =  [0, 0];
            posMgr.testCheckMinReserves(amounts4, amountsMin4);

            const amounts5 =  [0, 0];
            const amountsMin5 =  [0, 0];
            posMgr.testCheckMinReserves(amounts5, amountsMin5);
        });

        it("#checkMinCollateral should revert when Amounts < AmountsMin", async function () {
            const amounts =  [90000, 1000];
            const amountsMin =  [90000, 1001];
            await expect(posMgr.testCheckMinCollateral(amounts, amountsMin)).to.be.revertedWith("AmountsMin");

            const amounts0 =  [90000, 1000];
            const amountsMin0 =  [90001, 1000];
            await expect(posMgr.testCheckMinCollateral(amounts0, amountsMin0)).to.be.revertedWith("AmountsMin");

            const amounts1 =  [90000, 1000];
            const amountsMin1 =  [90001, 1001];
            await expect(posMgr.testCheckMinCollateral(amounts1, amountsMin1)).to.be.revertedWith("AmountsMin");

            const amounts2 =  [1, 1];
            const amountsMin2 =  [1, 2];
            await expect(posMgr.testCheckMinCollateral(amounts2, amountsMin2)).to.be.revertedWith("AmountsMin");

            const amounts3 =  [0, 1];
            const amountsMin3 =  [1, 1];
            await expect(posMgr.testCheckMinCollateral(amounts3, amountsMin3)).to.be.revertedWith("AmountsMin");

            const amounts4 =  [1, 0];
            const amountsMin4 =  [1, 1];
            await expect(posMgr.testCheckMinCollateral(amounts4, amountsMin4)).to.be.revertedWith("AmountsMin");

            const amounts5 =  [0, 0];
            const amountsMin5 =  [1, 1];
            await expect(posMgr.testCheckMinCollateral(amounts5, amountsMin5)).to.be.revertedWith("AmountsMin");
        });

        it("#checkMinCollateral should not revert when Amounts >= AmountsMin", async function () {
            const amounts =  [90000, 1000];
            const amountsMin =  [90000, 1000];
            posMgr.testCheckMinCollateral(amounts, amountsMin);

            const amounts0 =  [90001, 1000];
            const amountsMin0 =  [90000, 1000];
            posMgr.testCheckMinCollateral(amounts0, amountsMin0);

            const amounts1 =  [90000, 1001];
            const amountsMin1 =  [90000, 1000];
            posMgr.testCheckMinCollateral(amounts1, amountsMin1);

            const amounts2 =  [90001, 1001];
            const amountsMin2 =  [90000, 1000];
            posMgr.testCheckMinCollateral(amounts2, amountsMin2);

            const amounts3 =  [1, 1];
            const amountsMin3 =  [1, 1];
            posMgr.testCheckMinCollateral(amounts3, amountsMin3);

            const amounts4 =  [1, 1];
            const amountsMin4 =  [0, 0];
            posMgr.testCheckMinCollateral(amounts4, amountsMin4);

            const amounts5 =  [0, 0];
            const amountsMin5 =  [0, 0];
            posMgr.testCheckMinCollateral(amounts5, amountsMin5);
        });
    });

    // You can nest describe calls to create subsections.
    describe("Short Gamma Functions", function () {
        it("#depositNoPull should return shares", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const DepositWithdrawParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
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
            const DepositWithdrawParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
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
            const DepositReservesParams = {
                cfmm: cfmm.address,
                amountsDesired: [10000, 100],
                amountsMin: [1000, 10],
                to: addr4.address,
                protocolId: protocolId,
                deadline: ethers.constants.MaxUint256
            }
            const res0 = await (await posMgr.depositReserves(DepositReservesParams)).wait();

            const { args } = res0.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.reserves.length).to.equal(4);
            expect(args.shares.toNumber()).to.equal(18);

            const res1 = await posMgr.getPoolsWithOwnerLPBalance([args.pool], addr4.address);
            expect(res1._pools[0].poolId).to.equal(gammaPool.address);
            expect(res1._balances[0]).to.equal(18);

            const DepositReservesParams1 = {
                cfmm: cfmm.address,
                amountsDesired: [10000, 100],
                amountsMin: [1000, 10],
                to: owner.address,
                protocolId: protocolId,
                deadline: ethers.constants.MaxUint256
            }
            await (await posMgr.depositReserves(DepositReservesParams1)).wait();
            const res2 = await posMgr.getPoolsWithOwnerLPBalance([args.pool], addr4.address);
            expect(res2._pools[0].poolId).to.equal(gammaPool.address);
            expect(res2._balances[0]).to.equal(18);
        });

        it("#withdrawReserves should return assets and lenght of reserves", async function () {
            const WithdrawReservesParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                amount: 1000,
                amountsMin: [100, 200, 300],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }

            const res = await (await posMgr.withdrawReserves(WithdrawReservesParams)).wait();

            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.reserves.length).to.equal(3);
            expect(args.reserves[0]).to.equal(200);
            expect(args.reserves[1]).to.equal(300);
            expect(args.reserves[2]).to.equal(400);
            expect(args.assets.toNumber()).to.equal(17);
        });
    });

    // You can nest describe calls to create subsections.
    describe("Long Gamma Functions", function () {
        it("#createLoan should return tokenId", async function () {
            const res = await (await posMgr.createLoan(1, cfmm.address, owner.address, ethers.constants.MaxUint256)).wait();

            const latestBlock = await ethers.provider.getBlock("latest");
            const num = latestBlock.number * 100;
            const expTokenId = num + 19;

            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.owner).to.equal(owner.address);
            expect(args.tokenId.toNumber()).to.equal(expTokenId);

            const res1 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res1.length).to.equal(1);
            expect(res1[0].tokenId.toNumber()).to.equal(25);

            await (await posMgr.createLoan(1, cfmm.address, owner.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm.address, owner.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm.address, owner.address, ethers.constants.MaxUint256)).wait();

            const res2 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res2.length).to.equal(4);

            const res3 = await posMgr.getLoansByOwnerAndPool(addr1.address, gammaPool.address, 0, 10);
            expect(res3.length).to.equal(0);

            await (await posMgr.createLoan(1, cfmm.address, addr1.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm.address, addr1.address, ethers.constants.MaxUint256)).wait();

            const res4 = await posMgr.getLoansByOwnerAndPool(addr1.address, gammaPool.address, 0, 10);
            expect(res4.length).to.equal(2);

            await (await posMgr.createLoan(1, cfmm2.address, addr1.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm2.address, addr1.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm2.address, addr1.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm2.address, addr1.address, ethers.constants.MaxUint256)).wait();
            await (await posMgr.createLoan(1, cfmm2.address, addr1.address, ethers.constants.MaxUint256)).wait();

            const res5 = await posMgr.getLoansByOwnerAndPool(addr1.address, gammaPool2.address, 0, 10);
            expect(res5.length).to.equal(5);

            const res6 = await posMgr.getLoansByOwnerAndPool(addr1.address, gammaPool2.address, 0, 2);
            expect(res6.length).to.equal(3);

            const res7 = await posMgr.getLoansByOwner(addr1.address, 0, 100);
            expect(res7.length).to.equal(7);

            await (await posMgr.createLoan(1, cfmm3.address, addr1.address, ethers.constants.MaxUint256)).wait();

            const res8 = await posMgr.getLoansByOwner(addr1.address, 0, 100);
            expect(res8.length).to.equal(8);

            const res9 = await posMgr.getLoansByOwnerAndPool(addr1.address, gammaPool3.address, 0, 100);
            expect(res9.length).to.equal(1);
        });

        it("#transfer loan", async function () {
            const res0a = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res0a.length).to.eq(0);
            const res0b = await posMgr.getLoansByOwner(owner.address, 0, 10);
            expect(res0b.length).to.eq(0);
            const res1a = await posMgr.getLoansByOwnerAndPool(addr4.address, gammaPool.address, 0, 10);
            expect(res1a.length).to.eq(0);
            const res1b = await posMgr.getLoansByOwner(addr4.address, 0, 10);
            expect(res1b.length).to.eq(0);

            const res = await (await posMgr.createLoan(1, cfmm.address, owner.address, ethers.constants.MaxUint256)).wait();
            const latestBlock = await ethers.provider.getBlock("latest");
            const num = latestBlock.number * 100;
            const expTokenId = num + 19;
            const { args } = res.events[1];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.owner).to.equal(owner.address);
            expect(args.tokenId.toNumber()).to.equal(expTokenId);

            const res1 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res1.length).to.eq(1);
            expect(res1[0].tokenId).to.eq(25);
            const res2 = await posMgr.getLoansByOwner(owner.address, 0, 10);
            expect(res2.length).to.eq(1);
            expect(res2[0].tokenId).to.eq(25);

            await (await posMgr.transferFrom(owner.address, addr4.address, expTokenId)).wait();

            const res3 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res3.length).to.eq(1);
            expect(res3[0].tokenId).to.eq(0);
            const res4 = await posMgr.getLoansByOwner(owner.address, 0, 10);
            expect(res4.length).to.eq(1);
            expect(res4[0].tokenId).to.eq(0);

            const res5 = await posMgr.getLoansByOwnerAndPool(addr4.address, gammaPool.address, 0, 10);
            expect(res5.length).to.eq(1);
            expect(res5[0].tokenId).to.eq(25);
            const res6 = await posMgr.getLoansByOwner(addr4.address, 0, 10);
            expect(res6.length).to.eq(1);
            expect(res6[0].tokenId).to.eq(25);

            await (await posMgr.connect(addr4).transferFrom(addr4.address, owner.address, expTokenId)).wait();

            const res7 = await posMgr.getLoansByOwnerAndPool(addr4.address, gammaPool.address, 0, 10);
            expect(res7.length).to.eq(1);
            expect(res7[0].tokenId).to.eq(0);
            const res8 = await posMgr.getLoansByOwner(addr4.address, 0, 10);
            expect(res8.length).to.eq(1);
            expect(res8[0].tokenId).to.eq(0);

            const res9 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res9.length).to.eq(2);
            expect(res9[0].tokenId).to.eq(0);
            expect(res9[1].tokenId).to.eq(25);
            const res10 = await posMgr.getLoansByOwner(owner.address, 0, 10);
            expect(res10.length).to.eq(2);
            expect(res10[0].tokenId).to.eq(0);
            expect(res10[1].tokenId).to.eq(25);
        });

        it("#borrowLiquidity should return tokenId", async function () {
            const BorrowLiquidityParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                tokenId: tokenId,
                lpTokens: 1,
                minBorrowed: [0,0],
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.borrowLiquidity(BorrowLiquidityParams)).wait();
            
            const { args } = res.events[0];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.liquidityBorrowed).to.equal(23);
            expect(args.amounts.length).to.equal(2);
        });

        it("#repayLiquidity should return tokenId, paid liquidity, paid lp tokens and length of amounts array", async function () {
            const RepayLiquidityParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                tokenId: tokenId,
                liquidity: 1,
                minRepaid: [0,0],
                deadline: ethers.constants.MaxUint256,
                fees: [],
            }
            
            const res = await (await posMgr.repayLiquidity(RepayLiquidityParams)).wait();
            
            const { args } = res.events[0];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.liquidityPaid).to.equal(24);
            expect(args.amounts.length).to.equal(2);
        });

        it("#repayLiquidity should return tokenId, paid liquidity, paid lp tokens and length of amounts array with fees", async function () {
            const RepayLiquidityParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                tokenId: tokenId,
                liquidity: 1,
                minRepaid: [0,0],
                deadline: ethers.constants.MaxUint256,
                fees: [0,0],
            }

            const res = await (await posMgr.repayLiquidity(RepayLiquidityParams)).wait();

            const { args } = res.events[0];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.liquidityPaid).to.equal(26);
            expect(args.amounts.length).to.equal(2);
        });

        it("#increaseCollateral should return tokenId and length of tokens held", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256); // must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256); // must approve before sending tokens

            const AddRemoveCollateralParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                tokenId: tokenId,
                amounts: [100,10],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.increaseCollateral(AddRemoveCollateralParams)).wait();
            
            const { args } = res.events[2];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeld.length).to.equal(6);
        });

        it("#decreaseCollateral should return tokenId and length of tokens held", async function () {
            const AddRemoveCollateralParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                tokenId: tokenId,
                amounts: [100,10],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.decreaseCollateral(AddRemoveCollateralParams)).wait();
            
            const { args } = res.events[0];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeld.length).to.equal(7);
        });

        it("#rebalanceCollateral should return tokenId and length of tokens held", async function () {
            const RebalanceCollateralParams = {
                cfmm: cfmm.address,
                protocolId: protocolId,
                tokenId: tokenId,
                deltas: [4, 2],
                liquidity: 1,
                minCollateral: [0,0],
                deadline: ethers.constants.MaxUint256
            }
            
            const res = await (await posMgr.rebalanceCollateral(RebalanceCollateralParams)).wait();
            
            const { args } = res.events[0];
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(tokenId);
            expect(args.tokensHeld.length).to.equal(2);
        });

        it("#createLoanBorrowAndRebalance should return tokenId, tokensHeld, amounts. No deltas", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256); // must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256); // must approve before sending tokens

            const CreateLoanBorrowAndRebalanceParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                lpTokens: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                minBorrowed: [0,0],
                deltas: [],
                minCollateral: []
            }

            const res = await (await posMgr.createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams)).wait();

            const latestBlock = await ethers.provider.getBlock("latest");
            const num = latestBlock.number * 100;
            const expTokenId = num + 19;

            expect(res.events[1].event).to.equal("CreateLoan");
            const args0 = res.events[1].args;
            expect(args0.pool).to.equal(gammaPool.address);
            expect(args0.owner).to.equal(owner.address);
            expect(args0.tokenId.toNumber()).to.equal(expTokenId);

            expect(res.events[4].event).to.equal("IncreaseCollateral");
            const args1 = res.events[4].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(expTokenId);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[5].event).to.equal("BorrowLiquidity");
            const args2 = res.events[5].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(expTokenId);
            expect(args2.liquidityBorrowed).to.equal(23);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[6].event).to.equal("LoanUpdate");
            const args3 = res.events[6].args;
            expect(args3.poolId).to.equal(gammaPool.address);
            expect(args3.owner).to.equal(owner.address);
            expect(args3.tokensHeld.length).to.equal(5);
            expect(args3.liquidity.toNumber()).to.equal(21);
            expect(args3.lpTokens.toNumber()).to.equal(22);
            expect(args3.initLiquidity.toNumber()).to.equal(24);
            expect(args3.cfmmReserves.length).to.equal(2);
            expect(args3.cfmmReserves[0]).to.equal(0);
            expect(args3.cfmmReserves[1]).to.equal(0);

            const res1 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 0, 10);
            expect(res1.length).to.equal(1);
            expect(res1[0].tokenId).to.equal(25);

            const res2 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool2.address, 0, 10);
            expect(res2.length).to.equal(0);

            const res3 = await posMgr.getLoansByOwnerAndPool(owner.address, gammaPool.address, 5, 10);
            expect(res3.length).to.equal(0);
        });

        it("#createLoanBorrowAndRebalance should return tokenId, tokensHeld, amounts. Has deltas", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256); // must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256); // must approve before sending tokens

            const CreateLoanBorrowAndRebalanceParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                lpTokens: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                minBorrowed: [0,0],
                deltas: [4,2],
                minCollateral: [0,0]
            }

            const res = await (await posMgr.createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams)).wait();

            const latestBlock = await ethers.provider.getBlock("latest");
            const num = latestBlock.number * 100;
            const expTokenId = num + 19;

            expect(res.events[1].event).to.equal("CreateLoan");
            const args0 = res.events[1].args;
            expect(args0.pool).to.equal(gammaPool.address);
            expect(args0.owner).to.equal(owner.address);
            expect(args0.tokenId.toNumber()).to.equal(expTokenId);

            expect(res.events[4].event).to.equal("IncreaseCollateral");
            const args1 = res.events[4].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(expTokenId);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[5].event).to.equal("BorrowLiquidity");
            const args2 = res.events[5].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(expTokenId);
            expect(args2.liquidityBorrowed).to.equal(23);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[6].event).to.equal("RebalanceCollateral");
            const args3 = res.events[6].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(expTokenId);
            expect(args3.tokensHeld.length).to.equal(2);

            expect(res.events[7].event).to.equal("LoanUpdate");
            const args4 = res.events[7].args;
            expect(args4.poolId).to.equal(gammaPool.address);
            expect(args4.owner).to.equal(owner.address);
            expect(args4.tokensHeld.length).to.equal(5);
            expect(args4.liquidity.toNumber()).to.equal(21);
            expect(args4.lpTokens.toNumber()).to.equal(22);
            expect(args4.initLiquidity.toNumber()).to.equal(24);
            expect(args4.cfmmReserves.length).to.equal(2);
            expect(args4.cfmmReserves[0]).to.equal(0);
            expect(args4.cfmmReserves[1]).to.equal(0);
        });

        it("#borrowAndRebalance should return tokensHeld, amounts. No deltas", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const BorrowAndRebalanceParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                lpTokens: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                withdraw: [],
                minBorrowed: [0,0],
                deltas: [],
                minCollateral: []
            }

            const res = await (await posMgr.borrowAndRebalance(BorrowAndRebalanceParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("BorrowLiquidity");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.liquidityBorrowed).to.equal(23);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[4].event).to.equal("LoanUpdate");
            const args3 = res.events[4].args;
            expect(args3.poolId).to.equal(gammaPool.address);
            expect(args3.owner).to.equal(owner.address);
            expect(args3.tokensHeld.length).to.equal(5);
            expect(args3.liquidity.toNumber()).to.equal(21);
            expect(args3.lpTokens.toNumber()).to.equal(22);
            expect(args3.initLiquidity.toNumber()).to.equal(24);
            expect(args3.cfmmReserves.length).to.equal(2);
            expect(args3.cfmmReserves[0]).to.equal(0);
            expect(args3.cfmmReserves[1]).to.equal(0);
        });

        it("#borrowAndRebalance should return tokensHeld, amounts. No deltas, withdraws", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const BorrowAndRebalanceParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                lpTokens: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100, 10],
                withdraw: [2, 2],
                minBorrowed: [0, 0],
                deltas: [],
                minCollateral: []
            }

            const res = await (await posMgr.borrowAndRebalance(BorrowAndRebalanceParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("BorrowLiquidity");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.liquidityBorrowed).to.equal(23);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[4].event).to.equal("DecreaseCollateral");
            const args3 = res.events[4].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.tokensHeld.length).to.equal(7);

            expect(res.events[5].event).to.equal("LoanUpdate");
            const args4 = res.events[5].args;
            expect(args4.poolId).to.equal(gammaPool.address);
            expect(args4.owner).to.equal(owner.address);
            expect(args4.tokensHeld.length).to.equal(5);
            expect(args4.liquidity.toNumber()).to.equal(21);
            expect(args4.lpTokens.toNumber()).to.equal(22);
            expect(args4.initLiquidity.toNumber()).to.equal(24);
            expect(args4.cfmmReserves.length).to.equal(2);
            expect(args4.cfmmReserves[0]).to.equal(0);
            expect(args4.cfmmReserves[1]).to.equal(0);
        });

        it("#borrowAndRebalance should return tokensHeld, amounts. Has deltas", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const BorrowAndRebalanceParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                lpTokens: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                withdraw: [],
                minBorrowed: [0,0],
                deltas: [4,2],
                minCollateral: [0,0]
            }

            const res = await (await posMgr.borrowAndRebalance(BorrowAndRebalanceParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("BorrowLiquidity");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.liquidityBorrowed).to.equal(23);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[4].event).to.equal("RebalanceCollateral");
            const args3 = res.events[4].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.tokensHeld.length).to.equal(2);

            expect(res.events[5].event).to.equal("LoanUpdate");
            const args4 = res.events[5].args;
            expect(args4.poolId).to.equal(gammaPool.address);
            expect(args4.owner).to.equal(owner.address);
            expect(args4.tokensHeld.length).to.equal(5);
            expect(args4.liquidity.toNumber()).to.equal(21);
            expect(args4.lpTokens.toNumber()).to.equal(22);
            expect(args4.initLiquidity.toNumber()).to.equal(24);
            expect(args4.cfmmReserves.length).to.equal(2);
            expect(args4.cfmmReserves[0]).to.equal(0);
            expect(args4.cfmmReserves[1]).to.equal(0);
        });

        it("#rebalanceRepayAndWithdraw should return tokensHeld, liquidityPaid, amounts. No deltas, No Withdraw", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                withdraw: [],
                minRepaid: [0,0],
                deltas: [],
                minCollateral: [],
                fees: [1,1]
            }

            const res = await (await posMgr.rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("RepayLiquidity");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.liquidityPaid.toNumber()).to.equal(28);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[4].event).to.equal("LoanUpdate");
            const args3 = res.events[4].args;
            expect(args3.poolId).to.equal(gammaPool.address);
            expect(args3.owner).to.equal(owner.address);
            expect(args3.tokensHeld.length).to.equal(5);
            expect(args3.liquidity.toNumber()).to.equal(21);
            expect(args3.lpTokens.toNumber()).to.equal(22);
            expect(args3.initLiquidity.toNumber()).to.equal(24);
            expect(args3.cfmmReserves.length).to.equal(2);
            expect(args3.cfmmReserves[0]).to.equal(0);
            expect(args3.cfmmReserves[1]).to.equal(0);
        });

        it("#rebalanceRepayAndWithdraw should return tokensHeld, liquidityPaid, amounts. No deltas, Has Withdraw", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                withdraw: [100,10],
                minRepaid: [0,0],
                deltas: [],
                minCollateral: [0, 0],
                fees: []
            }

            const res = await (await posMgr.rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("RepayLiquidity");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.liquidityPaid.toNumber()).to.equal(24);
            expect(args2.amounts.length).to.equal(2);

            expect(res.events[4].event).to.equal("DecreaseCollateral");
            const args3 = res.events[4].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.tokensHeld.length).to.equal(7);

            expect(res.events[5].event).to.equal("LoanUpdate");
            const args4 = res.events[5].args;
            expect(args4.poolId).to.equal(gammaPool.address);
            expect(args4.owner).to.equal(owner.address);
            expect(args4.tokensHeld.length).to.equal(5);
            expect(args4.liquidity.toNumber()).to.equal(21);
            expect(args4.lpTokens.toNumber()).to.equal(22);
            expect(args4.initLiquidity.toNumber()).to.equal(24);
            expect(args4.cfmmReserves.length).to.equal(2);
            expect(args4.cfmmReserves[0]).to.equal(0);
            expect(args4.cfmmReserves[1]).to.equal(0);
        });

        it("#rebalanceRepayAndWithdraw should return tokensHeld, liquidityPaid, amounts. Has deltas, No Withdraw", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                withdraw: [],
                minRepaid: [0,0],
                deltas: [4,2],
                minCollateral: [0,0],
                fees: [0,1]
            }

            const res = await (await posMgr.rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("RebalanceCollateral");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.tokensHeld.length).to.equal(2);

            expect(res.events[4].event).to.equal("RepayLiquidity");
            const args3 = res.events[4].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.liquidityPaid.toNumber()).to.equal(27);
            expect(args3.amounts.length).to.equal(2);

            expect(res.events[5].event).to.equal("LoanUpdate");
            const args4 = res.events[5].args;
            expect(args4.poolId).to.equal(gammaPool.address);
            expect(args4.owner).to.equal(owner.address);
            expect(args4.tokensHeld.length).to.equal(5);
            expect(args4.liquidity.toNumber()).to.equal(21);
            expect(args4.lpTokens.toNumber()).to.equal(22);
            expect(args4.initLiquidity.toNumber()).to.equal(24);
            expect(args4.cfmmReserves.length).to.equal(2);
            expect(args4.cfmmReserves[0]).to.equal(0);
            expect(args4.cfmmReserves[1]).to.equal(0);
        });

        it("#rebalanceRepayAndWithdraw should return tokenId, tokensHeld, amounts. Has deltas, Has Withdraw", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [100,10],
                withdraw: [100,10],
                minRepaid: [0,0],
                deltas: [4,2],
                minCollateral: [0,0],
                fees: [3,5]
            }

            const res = await (await posMgr.rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[2].event).to.equal("IncreaseCollateral");
            const args1 = res.events[2].args;
            expect(args1.pool).to.equal(gammaPool.address);
            expect(args1.tokenId.toNumber()).to.equal(1);
            expect(args1.tokensHeld.length).to.equal(6);

            expect(res.events[3].event).to.equal("RebalanceCollateral");
            const args2 = res.events[3].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.tokensHeld.length).to.equal(2);

            expect(res.events[4].event).to.equal("RepayLiquidity");
            const args3 = res.events[4].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.liquidityPaid.toNumber()).to.equal(34);
            expect(args3.amounts.length).to.equal(2);

            expect(res.events[5].event).to.equal("DecreaseCollateral");
            const args4 = res.events[5].args;
            expect(args4.pool).to.equal(gammaPool.address);
            expect(args4.tokenId.toNumber()).to.equal(1);
            expect(args4.tokensHeld.length).to.equal(7);

            expect(res.events[6].event).to.equal("LoanUpdate");
            const args5 = res.events[6].args;
            expect(args5.poolId).to.equal(gammaPool.address);
            expect(args5.owner).to.equal(owner.address);
            expect(args5.tokensHeld.length).to.equal(5);
            expect(args5.liquidity.toNumber()).to.equal(21);
            expect(args5.lpTokens.toNumber()).to.equal(22);
            expect(args5.initLiquidity.toNumber()).to.equal(24);
            expect(args5.cfmmReserves.length).to.equal(2);
            expect(args5.cfmmReserves[0]).to.equal(0);
            expect(args5.cfmmReserves[1]).to.equal(0);
        });

        it("#rebalanceRepayAndWithdraw should return tokenId, tokensHeld, amounts. No Deposit, Has deltas, Has Withdraw", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: protocolId,
                cfmm: cfmm.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [],
                withdraw: [100,10],
                minRepaid: [0,0],
                deltas: [4,2],
                minCollateral: [0,0],
                fees: [0,1,10]
            }

            const res = await (await posMgr.rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[0].event).to.equal("RebalanceCollateral");
            const args2 = res.events[0].args;
            expect(args2.pool).to.equal(gammaPool.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.tokensHeld.length).to.equal(2);

            expect(res.events[1].event).to.equal("RepayLiquidity");
            const args3 = res.events[1].args;
            expect(args3.pool).to.equal(gammaPool.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.liquidityPaid.toNumber()).to.equal(27);
            expect(args3.amounts.length).to.equal(2);

            expect(res.events[2].event).to.equal("DecreaseCollateral");
            const args4 = res.events[2].args;
            expect(args4.pool).to.equal(gammaPool.address);
            expect(args4.tokenId.toNumber()).to.equal(1);
            expect(args4.tokensHeld.length).to.equal(7);

            expect(res.events[3].event).to.equal("LoanUpdate");
            const args5 = res.events[3].args;
            expect(args5.poolId).to.equal(gammaPool.address);
            expect(args5.owner).to.equal(owner.address);
            expect(args5.tokensHeld.length).to.equal(5);
            expect(args5.liquidity.toNumber()).to.equal(21);
            expect(args5.lpTokens.toNumber()).to.equal(22);
            expect(args5.initLiquidity.toNumber()).to.equal(24)
            expect(args5.cfmmReserves.length).to.equal(2);
            expect(args5.cfmmReserves[0]).to.equal(0);
            expect(args5.cfmmReserves[1]).to.equal(0);
        });

        it("#closeLoan should pass empty withdraw array", async function () {
            const implementation2 = await GammaPool2.deploy(2, factory.address, addr1.address, addr2.address, addr3.address);
            await (await factory.addProtocol(implementation2.address)).wait();
            const createPoolParams2 = {
                cfmm: cfmm3.address,
                protocolId: 2,
                tokens: [tokenA.address, tokenB.address]
            };
            const data = ethers.utils.defaultAbiCoder.encode(
                [],
                []
            );
            const res4 = await (await factory.createPool(createPoolParams2.protocolId, cfmm3.address ,createPoolParams2.tokens, data)).wait();

            gammaPoolAddr4 = res4.events[1].args.pool;
            gammaPool4 = await GammaPool.attach(
                gammaPoolAddr4 // The deployed contract address
            );
            await gammaPool4.approve(posMgr.address, ethers.constants.MaxUint256);
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: 2,
                cfmm: cfmm3.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [],
                withdraw: [100,10],
                minRepaid: [0,0],
                deltas: [4,2],
                minCollateral: [0,0],
                fees: [0,1]
            }

            await expect(posMgr.closeLoan(RebalanceRepayAndWithdrawParams)).to.be.revertedWith("AmountsMin");

            RebalanceRepayAndWithdrawParams.withdraw = [];

            const res = await (await posMgr.closeLoan(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[0].event).to.equal("RebalanceCollateral");
            const args2 = res.events[0].args;
            expect(args2.pool).to.equal(gammaPool4.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.tokensHeld.length).to.equal(2);

            expect(res.events[1].event).to.equal("RepayLiquidity");
            const args3 = res.events[1].args;
            expect(args3.pool).to.equal(gammaPool4.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.liquidityPaid.toNumber()).to.equal(27);
            expect(args3.amounts.length).to.equal(2);

            expect(res.events[2].event).to.equal("DecreaseCollateral");
            const args4 = res.events[2].args;
            expect(args4.pool).to.equal(gammaPool4.address);
            expect(args4.tokenId.toNumber()).to.equal(1);
            expect(args4.tokensHeld.length).to.equal(7);

            expect(res.events[3].event).to.equal("LoanUpdate");
            const args5 = res.events[3].args;
            expect(args5.poolId).to.equal(gammaPool4.address);
            expect(args5.owner).to.equal(owner.address);
            expect(args5.tokensHeld.length).to.equal(2);
            expect(args5.liquidity.toNumber()).to.equal(21);
            expect(args5.lpTokens.toNumber()).to.equal(22);
            expect(args5.initLiquidity.toNumber()).to.equal(24)
            expect(args5.cfmmReserves.length).to.equal(2);
            expect(args5.cfmmReserves[0]).to.equal(0);
            expect(args5.cfmmReserves[1]).to.equal(0);
        });

        it("#closeLoan should pass withdraw array of zeroes", async function () {
            const implementation2 = await GammaPool2.deploy(2, factory.address, addr1.address, addr2.address, addr3.address);
            await (await factory.addProtocol(implementation2.address)).wait();
            const createPoolParams2 = {
                cfmm: cfmm3.address,
                protocolId: 2,
                tokens: [tokenA.address, tokenB.address]
            };
            const data = ethers.utils.defaultAbiCoder.encode(
                [],
                []
            );
            const res4 = await (await factory.createPool(createPoolParams2.protocolId, cfmm3.address ,createPoolParams2.tokens, data)).wait();

            gammaPoolAddr4 = res4.events[1].args.pool;
            gammaPool4 = await GammaPool.attach(
                gammaPoolAddr4 // The deployed contract address
            );
            await gammaPool4.approve(posMgr.address, ethers.constants.MaxUint256);
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const RebalanceRepayAndWithdrawParams = {
                protocolId: 2,
                cfmm: cfmm3.address,
                to: owner.address,
                tokenId: 1,
                liquidity: 1,
                deadline: ethers.constants.MaxUint256,
                amounts: [],
                withdraw: [100,10],
                minRepaid: [0,0],
                deltas: [4,2],
                minCollateral: [0,0],
                fees: [0,1]
            }

            await expect(posMgr.closeLoan(RebalanceRepayAndWithdrawParams)).to.be.revertedWith("AmountsMin");

            RebalanceRepayAndWithdrawParams.withdraw = [0, 0];

            const res = await (await posMgr.closeLoan(RebalanceRepayAndWithdrawParams)).wait();

            expect(res.events[0].event).to.equal("RebalanceCollateral");
            const args2 = res.events[0].args;
            expect(args2.pool).to.equal(gammaPool4.address);
            expect(args2.tokenId.toNumber()).to.equal(1);
            expect(args2.tokensHeld.length).to.equal(2);

            expect(res.events[1].event).to.equal("RepayLiquidity");
            const args3 = res.events[1].args;
            expect(args3.pool).to.equal(gammaPool4.address);
            expect(args3.tokenId.toNumber()).to.equal(1);
            expect(args3.liquidityPaid.toNumber()).to.equal(27);
            expect(args3.amounts.length).to.equal(2);

            expect(res.events[2].event).to.equal("DecreaseCollateral");
            const args4 = res.events[2].args;
            expect(args4.pool).to.equal(gammaPool4.address);
            expect(args4.tokenId.toNumber()).to.equal(1);
            expect(args4.tokensHeld.length).to.equal(7);

            expect(res.events[3].event).to.equal("LoanUpdate");
            const args5 = res.events[3].args;
            expect(args5.poolId).to.equal(gammaPool4.address);
            expect(args5.owner).to.equal(owner.address);
            expect(args5.tokensHeld.length).to.equal(2);
            expect(args5.liquidity.toNumber()).to.equal(21);
            expect(args5.lpTokens.toNumber()).to.equal(22);
            expect(args5.initLiquidity.toNumber()).to.equal(24);
            expect(args5.cfmmReserves.length).to.equal(2);
            expect(args5.cfmmReserves[0]).to.equal(0);
            expect(args5.cfmmReserves[1]).to.equal(0);
        });
    });
});
