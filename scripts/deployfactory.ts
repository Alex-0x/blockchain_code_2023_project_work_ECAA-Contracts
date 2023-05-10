import { ethers } from "hardhat";

async function main() {

    const address = "0x7adC1b0B0697cC518eb04c4c43ee3C55EA1Ddc24"
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
