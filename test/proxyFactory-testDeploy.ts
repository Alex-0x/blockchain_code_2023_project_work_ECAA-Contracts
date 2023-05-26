import { ethers } from "hardhat";
import { expect } from "chai";

describe("MultiSigWalletFactory", function() {
  let multisigWalletFactory: any;
  let multisigWalletImplementation: any;
  let owner1: any;
  let owner2: any;

  beforeEach(async function() {
    const MultisigWalletImplementation = await ethers.getContractFactory("MultiSigWallet");
    multisigWalletImplementation = await MultisigWalletImplementation.deploy();
    await multisigWalletImplementation.deployed();

    const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWalletFactory");
    multisigWalletFactory = await MultiSigWalletFactory.deploy(multisigWalletImplementation.address);
    await multisigWalletFactory.deployed();

    [owner1, owner2] = await ethers.getSigners();
  });

  it("should create a new multisig wallet proxy", async function() {
    const owners = [owner1.address, owner2.address];
    const numConfirmationsRequired = 2;
    const numThreshold = 1;

    const tx = await multisigWalletFactory.createWallet(owners, numConfirmationsRequired, numThreshold);
    const receipt = await tx.wait();
    const proxyCreatedEvent = receipt.events.find(
      (event: any) => event.event === "ProxyCreated"
    );

    const proxyAddress = proxyCreatedEvent.args.proxy;

    const multisigWallet = await ethers.getContractAt("MultiSigWallet", proxyAddress);
    const actualOwners = await multisigWallet.getOwners();
    const actualNumConfirmationsRequired = await multisigWallet.numConfirmationsRequired();
    const actualNumThreshold = await multisigWallet.numThreshold();

    expect(actualOwners).to.deep.equal(owners);
    expect(actualNumConfirmationsRequired).to.equal(numConfirmationsRequired);
    expect(actualNumThreshold).to.equal(numThreshold);
  });

});