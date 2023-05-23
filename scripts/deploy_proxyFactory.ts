import { ethers } from "hardhat";

async function main() {

    const address = "0xBedE777b758EFDcA27dc1Ee09022366844658135"
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