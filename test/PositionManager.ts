const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PositionManager", function () {
  let TestERC20: any;
  let TestGammaPool: any;
  let TestGammaPoolFactory: any;
  let PositionManager: any;
  let erc20: any;
  let factory: any;
  let initCodeHash: any;
  let positionManager: any;
  let owner: any;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    TestERC20 = await ethers.getContractFactory("TestERC20");
    erc20 = await TestERC20.deploy();
    TestGammaPool = await ethers.getContractFactory("TestGammaPool");
    initCodeHash = ethers.utils.keccak256(
      TestGammaPool.bytecode
    );
    TestGammaPoolFactory = await ethers.getContractFactory("TestGammaPoolFactory");
    factory = await TestGammaPoolFactory.deploy();

    PositionManager = await ethers.getContractFactory("PositionManager");
    positionManager = await PositionManager.deploy(factory.address, erc20.address, initCodeHash);

    await positionManager.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await positionManager.owner()).to.equal(owner.address);
    });

    it("Should set the right initials", async function () {
      expect(await positionManager.factory()).to.equal(factory.address);
      expect(await positionManager.initCodeHash()).to.equal(initCodeHash);
    });
  });

  describe("Short Gamma", function () {
    it("#deposit to pool", async function () {
      console.log((await positionManager.depositNoPull()).toString());
      // expect(await positionManager.depositNoPull()).to.equal(factory.address);
    });
  });
});