import { ethers } from "hardhat";

async function main() {
  const wethAddress = "<get this from deployPreCore deploy logs>";
  const GammaFactoryAddress = "<get this from v1core deploy logs>";
  const COMPUTED_INIT_CODE_HASH =
    "0x157cb49461412afba53e7bd9359b3da3e81a31825666371966e5354af6fe2693";
    // This value come from v1-core. If this gives an error, then the hash may
    // need to be updated.

  const PositionManager = await ethers.getContractFactory("PositionManager");
  const positionManager = await PositionManager.deploy(GammaFactoryAddress,
    wethAddress, COMPUTED_INIT_CODE_HASH);
  await positionManager.deployed();
  console.log("PositionManager Address >> ", positionManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
