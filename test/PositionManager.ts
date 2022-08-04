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
        });/**/
    });
    // You can nest describe calls to create subsections.
    describe("Long Gamma", function () {

    });
});
