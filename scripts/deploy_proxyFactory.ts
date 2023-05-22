import { ethers } from "hardhat";

async function main() {

    const address = "0xF0049d779ef97adece94863ED204C243f3DEDEBe"
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