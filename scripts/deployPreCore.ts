import { ethers } from "hardhat";
const UniswapV2FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
import type { TestERC20 } from "../typechain/TestERC20";
const UniswapV2PairJSON = require("@uniswap/v2-core/build/UniswapV2Pair.json");

async function main() {
  const [owner] = await ethers.getSigners();
  const TestERC20Contract = await ethers.getContractFactory("TestERC20");
  const tokenA = await TestERC20Contract.deploy("Test Token A", "TOKA");
  const tokenB = await TestERC20Contract.deploy("Test Token B", "TOKB");
  const tokenC = await TestERC20Contract.deploy("Test Token C", "TOKC");
  const WETH = await TestERC20Contract.deploy("WETH", "WETH");
  await tokenA.deployed();
  await tokenB.deployed();
  await tokenC.deployed();
  await WETH.deployed();
  console.log("tokenA Address >> " + tokenA.address);
  console.log("tokenB Address >> " + tokenB.address);
  console.log("tokenC Address >> " + tokenC.address);
  console.log("WETH Address >> " + WETH.address);

  const UniswapV2Factory = new ethers.ContractFactory(
    UniswapV2FactoryJSON.abi,
    UniswapV2FactoryJSON.bytecode,
    owner
  );

  const uniFactory = await UniswapV2Factory.deploy(owner.address);
  await uniFactory.deployed();
  console.log("UniswapV2Factory Address >> " + uniFactory.address);

  const UNI_COMPUTED_INIT_CODE_HASH = ethers.utils.keccak256(
    UniswapV2Factory.bytecode
  );
  console.log("uni factory hash >> " + UNI_COMPUTED_INIT_CODE_HASH)

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
  await createPair(tokenA, tokenC);
  await createPair(tokenB, tokenC);
  await createPair(tokenA, WETH);
  await createPair(tokenB, WETH);
  await createPair(tokenC, WETH);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
