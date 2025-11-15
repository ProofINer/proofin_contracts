import { ethers } from "hardhat";

async function main() {
  try {
    const [signer] = await ethers.getSigners();
    console.log("지갑 주소:", signer.address);
    console.log("잔고:", ethers.formatEther(await ethers.provider.getBalance(signer.address)), "ETH");
  } catch (error) {
    console.error("오류:", error instanceof Error ? error.message : String(error));
  }
}

main().catch(console.error);