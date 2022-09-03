import { ethers } from "hardhat";

async function main() {
  const tokenAaddr = "<from pre core logs>";
  const tokenBaddr = "<from pre core logs>";
  const metamaskAddress = "<address to sent to>";
  
  const [owner] = await ethers.getSigners();
  await owner.sendTransaction({
    to: metamaskAddress,
    value: ethers.utils.parseEther("100.0"), // Sends exactly 100.0 ether
  });
  
  const tokenA = await ethers.getContractAt("TestERC20", tokenAaddr);
  const tokenB = await ethers.getContractAt("TestERC20", tokenBaddr);
  await tokenA.transfer(metamaskAddress, ethers.utils.parseEther("100.0"));
  await tokenB.transfer(metamaskAddress, ethers.utils.parseEther("100.0"));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
