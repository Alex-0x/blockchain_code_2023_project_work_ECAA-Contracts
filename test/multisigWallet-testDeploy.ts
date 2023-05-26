import { ethers } from "hardhat";
import { expect } from "chai";


describe("MultisigWallet", function() {
  let _MultiSigWallet: any;

  beforeEach(async function() {
    const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
    _MultiSigWallet = await MultiSigWallet.deploy();
    await _MultiSigWallet.deployed();
  });

  it("should deploy the multisig wallet", async function() {
    expect(await _MultiSigWallet.deployed()).to.be.ok;
  });


});