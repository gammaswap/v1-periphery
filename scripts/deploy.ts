import { ethers } from "hardhat";
import type { TestERC20 } from "../typechain/TestERC20";
const UniswapV2FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const UniswapV2PairJSON = require("@uniswap/v2-core/build/UniswapV2Pair.json");

async function main() {
  // Get the ContractFactory and Signers here.
  const TestERC20 = await ethers.getContractFactory("TestERC20");
  const GammaPoolFactory = await ethers.getContractFactory("TestGammaPoolFactory");
  const PositionManager = await ethers.getContractFactory("PositionManager");
  const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

  // To deploy our contract, we just have to call Token.deploy() and await
  // for it to be deployed(), which happens onces its transaction has been
  // mined.
  const tokenA = await TestERC20.deploy("Test Token A", "TOKA");
  const tokenB = await TestERC20.deploy("Test Token B", "TOKB");
  const cfmm = await TestERC20.deploy("CFMM LP Token", "LP_CFMM");
  const WETH = await TestERC20.deploy("WETH", "WETH");
  const factory = await GammaPoolFactory.deploy(owner.address, addr1.address, addr2.address, addr3.address);
  const positionManager = await PositionManager.deploy(factory.address, WETH.address);

  await tokenA.deployed();
  await tokenB.deployed();
  await cfmm.deployed();
  await factory.deployed();
  await positionManager.deployed();

  const createPoolParams = {
    cfmm: cfmm.address,
    protocol: 1,
    tokens: [tokenA.address, tokenB.address]
  };

  const res = await (await factory.createPool(createPoolParams)).wait();
  if (res.events && res.events[1].args) {
    console.log("GSP deployed to:", res.events[1].args.pool);
  } else {
    console.log("Could not get GSP address. Please check" );
  }
  
  console.log("Token A deployed to:", tokenA.address);
  console.log("Token B deployed to:", tokenB.address);
  console.log("CFMM deployed to:", cfmm.address);
  console.log("GS factory deployed to:", factory.address);
  console.log("PositionManager deployed to:", positionManager.address);

  const UniswapV2Factory = new ethers.ContractFactory(
    UniswapV2FactoryJSON.abi,
    UniswapV2FactoryJSON.bytecode,
    owner
  );

  const uniFactory = await UniswapV2Factory.deploy(owner.address);
  await uniFactory.deployed();
  console.log("UniswapV2Factory Address >> " + uniFactory.address);

  async function createPair(token1: TestERC20, token2: TestERC20) {
    await uniFactory.createPair(token1.address, token2.address);
    const uniPairAddress: string = await uniFactory.getPair(
      token1.address,
      token2.address
    );
    const token1Symbol = await token1.symbol();
    const token2Symbol = await token2.symbol();
    console.log(token1Symbol + "/" + token2Symbol + " uniPairAddress >> "
      + uniPairAddress);

    // initial reserves
    const pair = new ethers.Contract(uniPairAddress, UniswapV2PairJSON.abi, owner);
    let amt = ethers.utils.parseEther("100");
    await token1.transfer(uniPairAddress, amt);
    await token2.transfer(uniPairAddress, amt);
    await pair.mint(owner.address);
  }

  await createPair(tokenA, tokenB);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
