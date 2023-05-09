import { ethers } from "hardhat";


async function main() {

    const PUBLIC_KEY =
        "0xfdB78b2AB4fF548CFa6eF069D994108cAE676765"
    const Test = await ethers.getContractFactory("MultiSigWallet");
    const test = await Test.deploy([PUBLIC_KEY, "0x4165279351bFA40e821ac16AeA60ed29d9c1Bb29"], 1, 1);

    await test.deployed();



    console.log(
        `Test deployed to ${test.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
