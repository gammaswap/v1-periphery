import { ethers } from "hardhat";

async function main() {
  // Get the ContractFactory and Signers here.
  const TestERC20 = await ethers.getContractFactory("TestERC20");
  const GammaPoolFactory = await ethers.getContractFactory("TestGammaPoolFactory");
  const PositionManager = await ethers.getContractFactory("PositionManager");
  const GammaPool = await ethers.getContractFactory("TestGammaPool");
  const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

  // To deploy our contract, we just have to call Token.deploy() and await
  // for it to be deployed(), which happens onces its transaction has been
  // mined.
  const tokenA = await TestERC20.deploy("Test Token A", "TOKA");
  const tokenB = await TestERC20.deploy("Test Token B", "TOKB");
  const cfmm = await TestERC20.deploy("CFMM LP Token", "LP_CFMM");
  const WETH = await TestERC20.deploy("WETH", "WETH");
  const factory = await GammaPoolFactory.deploy(owner.address, addr1.address, addr2.address, addr3.address);

  await tokenA.deployed();
  await tokenB.deployed();
  await cfmm.deployed();
  await factory.deployed();

  const COMPUTED_INIT_CODE_HASH = ethers.utils.keccak256(
    GammaPool.bytecode
  );

  const positionManager = await PositionManager.deploy(factory.address, WETH.address, COMPUTED_INIT_CODE_HASH);

  await positionManager.deployed();

  console.log("PositionManager deployed to:", positionManager.address);

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
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
