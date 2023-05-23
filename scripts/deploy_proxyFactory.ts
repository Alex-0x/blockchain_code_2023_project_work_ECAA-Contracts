import { ethers } from "hardhat";

async function main() {

    const address = "0xb27B8640CBccDa874182A9001bcCfA39B154C227"
    const Factory = await ethers.getContractFactory("MultiSigWalletFactory");
    const factory = await Factory.deploy(address);

    await factory.deployed();
    
    
    
    console.log(
        `Factory deployed to ${factory.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});