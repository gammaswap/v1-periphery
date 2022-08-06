import { ethers } from "hardhat";
import { expect } from "chai";

describe("GammaPoolFactory", function () {
    let TestERC20: any;
    let TestPoolAddress: any;
    let GammaPool: any;
    let GammaPoolFactory: any;
    let PositionManager: any;
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
    let createLoanArgs: any;

    // `beforeEach` will run before each test, re-deploying the contract every
    // time. It receives a callback, which can be async.
    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        TestERC20 = await ethers.getContractFactory("TestERC20");
        GammaPoolFactory = await ethers.getContractFactory("TestGammaPoolFactory");
        PositionManager = await ethers.getContractFactory("PositionManager");
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
        posMgr = await PositionManager.deploy(factory.address, WETH.address, COMPUTED_INIT_CODE_HASH);

        await posMgr.deployed();

        const createPoolParams = {
            cfmm: cfmm.address,
            protocol: 1,
            tokens: [tokenA.address, tokenB.address]
        };

        const res = await (await factory.createPool(createPoolParams)).wait();
        res.events.forEach(function(event: any, i: any){
            if(i == 0) {
                return;
            }
            gammaPoolAddr = event.args.pool;
            let _cfmm = event.args.cfmm;
            protocolId = event.args.protocolId;
            protocol = event.args.protocol;
            count = event.args.count.toString();
            console.log("pool: " + gammaPoolAddr);
            console.log("_cfmm: " + _cfmm);
            console.log("cfmm: " + cfmm.address);
            console.log("protocolId: " + protocolId);
            console.log("protocol: " + protocol);
            console.log("count: " + count);
        });

        gammaPool = await GammaPool.attach(
            gammaPoolAddr // The deployed contract address
        );

        const createLoanResponse = await (await posMgr.createLoan(cfmm.address, 1, owner.address, ethers.constants.MaxUint256)).wait();
        createLoanArgs = createLoanResponse.events[1].args
        tokenId = createLoanArgs.tokenId.toNumber()
    });

    describe("Base Functions", function () {
        it("sendTokensCallback should FORBIDDEN", async function () {
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

        it("sendTokensCallback should not be FORBIDDEN", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            const prevBalanceOwnerA = await tokenA.balanceOf(owner.address);
            const prevBalanceOwnerB = await tokenB.balanceOf(owner.address);

            const sendTokensCallback =  {
                payer: owner.address,
                cfmm: cfmm.address,
                protocol: 1,
            }
            const tokens = [tokenA.address, tokenB.address];
            const amounts =  [90000, 1000];
            const payee = addr1.address;
            const data = ethers.utils.defaultAbiCoder.encode(["tuple(address payer, address cfmm, uint24 protocol)"],[sendTokensCallback]);
            
            const res = await gammaPool.testTokenCallbackFunction(posMgr.address, tokens, amounts, payee, data)

            const newBalanceOwnerA = await tokenA.balanceOf(owner.address);
            const newBalanceOwnerB = await tokenB.balanceOf(owner.address);

            console.log("Previous Balance >>");
            console.log("TokenA: ", prevBalanceOwnerA.toString());
            console.log("TokenB: ", prevBalanceOwnerB.toString());
            
            console.log("New Balance >>");
            console.log("TokenA: ", newBalanceOwnerA.toString());
            console.log("TokenB: ", newBalanceOwnerB.toString());
                        
            await expect(prevBalanceOwnerA.toString()).to.not.be.equal(newBalanceOwnerA.toString());
        })
    });

    // You can nest describe calls to create subsections.
    describe("Short Gamma", function () {
        it("depositNoPull", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            const DepositWithdrawParams =  {
                cfmm: cfmm.address,
                protocol: 1,
                lpTokens: 1,
                to: addr4.address,
                deadline: ethers.constants.MaxUint256
            }
            const res = await (await posMgr.depositNoPull(DepositWithdrawParams)).wait();
            res.events.forEach(function(event: any, i: any){
                if(i == 0)
                    return;

                console.log("event >>");
                console.log(event.args);
                expect(event.args.pool).to.equal(gammaPool.address);
                expect(event.args.shares.toNumber()).to.equal(15);
            });
        });

        it("withdrawNoPull", async function () {
            await gammaPool.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const DepositWithdrawParams =  {
                cfmm: cfmm.address,
                protocol: 1,
                lpTokens: 1,
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }

            const res = await (await posMgr.withdrawNoPull(DepositWithdrawParams)).wait();
            res.events.forEach(function(event: any, i: any){
                if(i == 0)
                    return;
                console.log("event >>");
                console.log(event.args);
                expect(event.args.pool).to.equal(gammaPool.address);
                expect(event.args.assets.toNumber()).to.equal(16);
            });
        });

        it("depositReserves", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            const DepositReservesParams =  {
                cfmm: cfmm.address,
                amountsDesired: [10000, 100],
                amountsMin: [1000, 10],
                to: addr4.address,
                protocol: 1,
                deadline: ethers.constants.MaxUint256
            }
            const res = await (await posMgr.depositReserves(DepositReservesParams)).wait();
            res.events.forEach(function(event: any, i: any){
                expect(event.args).to.not.be.an('undefined');
                console.log("event >>");
                console.log(event.args);
                expect(event.args.pool).to.equal(gammaPool.address);
                expect(event.args.reservesLen).to.equal(4);
                expect(event.args.shares.toNumber()).to.equal(18);
            });
        });

        it("withdrawReserves", async function () {            
            await gammaPool.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

            const WithdrawReservesParams =  {
                cfmm: cfmm.address,
                protocol: 1,
                amount: 1000,
                amountsMin: [100, 200, 300],
                to: owner.address,
                deadline: ethers.constants.MaxUint256
            }

            const res = await (await posMgr.withdrawReserves(WithdrawReservesParams)).wait();

            res.events.forEach(function(event: any, i: any){
                if(i == 0)
                    return;
                console.log("event >>");
                console.log(event.args);
                expect(event.args.pool).to.equal(gammaPool.address);
                expect(event.args.reservesLen).to.equal(3);
                expect(event.args.assets.toNumber()).to.equal(17);
            });
        });
    });

    // You can nest describe calls to create subsections.
    describe("Long Gamma", function () {
        it("createLoan", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
            console.log("event >>");
            console.log(createLoanArgs);
            expect(createLoanArgs.pool).to.equal(gammaPool.address);
            expect(createLoanArgs.tokenId.toNumber()).to.equal(19);
        });

        it("borrowLiquidity", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens

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
            console.log("event >>");
            console.log(args);
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
        });

        it("repayLiquidity", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
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
            console.log("event >>");
            console.log(args);
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
            expect(args.liquidityPaid.toNumber()).to.equal(24);
            expect(args.lpTokensPaid.toNumber()).to.equal(25);
            expect(args.amountsLen.toNumber()).to.equal(9);
        });

        it("increaseCollateral", async function () {
            await tokenA.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await tokenB.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
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
            console.log("event >>");
            console.log(args);
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
            expect(args.tokensHeldLen.toNumber()).to.equal(6);
        });

        it("decreaseCollateral", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
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
            console.log("event >>");
            console.log(args);
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
            expect(args.tokensHeldLen.toNumber()).to.equal(7);
        });

        it("rebalanceCollateral", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
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
            console.log("event >>");
            console.log(args);
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
            expect(args.tokensHeldLen.toNumber()).to.equal(10);
        });

        it("rebalanceCollateralWithLiquidity", async function () {
            await cfmm.approve(posMgr.address, ethers.constants.MaxUint256);//must approve before sending tokens
            
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
            console.log("event >>");
            console.log(args);
            expect(args.pool).to.equal(gammaPool.address);
            expect(args.tokenId.toNumber()).to.equal(19);
            expect(args.tokensHeldLen.toNumber()).to.equal(11);
        });
    });
});
