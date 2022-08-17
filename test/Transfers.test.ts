import { ethers } from "hardhat";
import { expect } from "chai";

describe("Transfer", function () {
    let owner: any;
    let addr1: any;
    let TestTransfers: any;
    let testTransfersToken: any;
    let WETH: any;
    let TestERC20: any;
    let tokenWeth: any;
    let tokenA: any;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        TestERC20 = await ethers.getContractFactory("TestERC20");
        tokenA = await TestERC20.deploy("Token A", "TOKA");

        WETH = await ethers.getContractFactory("WETH9");
        tokenWeth = await WETH.deploy();

        await tokenWeth.deposit({value: ethers.utils.parseEther('100')});

        TestTransfers = await ethers.getContractFactory("TestTransfers");
        testTransfersToken = await TestTransfers.deploy(tokenWeth.address);

        await tokenWeth.transfer(testTransfersToken.address, 5000);
        await tokenA.transfer(testTransfersToken.address, 5000);

        await testTransfersToken.deployed();
        await tokenWeth.deployed();
        await tokenA.deployed();
    })

    it("#unwrapWETH", async function () {
        let currentAddr1Balance = await ethers.provider.getBalance(addr1.address)

        expect((await tokenWeth.balanceOf(testTransfersToken.address)).toNumber()).to.equal(5000);
        expect(await testTransfersToken.testUnwrapWETH(1000, addr1.address)).to.be.ok;
        expect((await tokenWeth.balanceOf(testTransfersToken.address)).toNumber()).to.equal(0);
        expect(await ethers.provider.getBalance(addr1.address)).to.equal(currentAddr1Balance.add(ethers.BigNumber.from(5000)));
    })

    it("#refundETH", async function () {
        await testTransfersToken.testUnwrapWETH(1000, testTransfersToken.address)
        // expect(await testTransfersToken.testRefundETH()).to.be.ok;
    })

    it("#clearToken", async function () {
        await tokenA.approve(testTransfersToken.address, ethers.constants.MaxUint256);

        expect((await tokenA.balanceOf(testTransfersToken.address)).toNumber()).to.equal(5000);
        expect(await testTransfersToken.testClearToken(tokenA.address, 1000, addr1.address)).to.be.ok;
        expect((await tokenA.balanceOf(testTransfersToken.address)).toNumber()).to.equal(0);
    })

    it("#send", async function () {
        await tokenA.approve(testTransfersToken.address, ethers.constants.MaxUint256);
        let amount = 1000;
        let currentAddr1Balance = await tokenA.balanceOf(addr1.address);

        expect((await tokenA.balanceOf(testTransfersToken.address)).toNumber()).to.equal(5000);
        expect(await testTransfersToken.testSend(tokenA.address, testTransfersToken.address, addr1.address, amount)).to.be.ok;
        expect((await tokenA.balanceOf(testTransfersToken.address)).toNumber()).to.equal(5000 - amount);
        expect((await tokenA.balanceOf(addr1.address)).toNumber()).to.equal(currentAddr1Balance.add(ethers.BigNumber.from(amount)));
    })
})