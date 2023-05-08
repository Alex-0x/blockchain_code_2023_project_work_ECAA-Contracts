import { ethers } from "hardhat";


async function main() {

    const PUBLIC_KEY =
        "0xfdB78b2AB4fF548CFa6eF069D994108cAE676765"
    const Test = await ethers.getContractFactory("MultiSigWalletTest");
    const test = await Test.deploy([PUBLIC_KEY, "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"], 1, 1);

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
