import { ethers } from "hardhat";

async function main() {

    const address = "0x06e196AA16731A6474B09f08D0DC38B06Dbe593e"
    const Factory = await ethers.getContractFactory("MultisigWalletFactory");
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
