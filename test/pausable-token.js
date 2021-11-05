const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Pausable Token", () => {
  let owner, addr1, PausableToken, token;

  before(async () => {
    [owner, addr1] = await ethers.getSigners();

    PausableToken = await ethers.getContractFactory("PausableToken");
    token = await PausableToken.deploy("1000000000000000000000000");
    await token.deployed();
  });

  it("Should have a a correct total supply", async () => {
    expect(await token.totalSupply()).to.equal("1000000000000000000000000");
  });

  it("Should have all supply allocated to owner", async () => {
    expect(await token.balanceOf(owner.address)).to.equal(await token.totalSupply());
  });

  it("Should be able to transfer tokens to another account", async () => {
    const transTx = await token.transfer(addr1.address, "10000000000000000000");

    // wait until the transaction is mined
    await transTx.wait();

    expect(await token.balanceOf(addr1.address)).to.equal("10000000000000000000");
    expect(await token.balanceOf(owner.address)).to.equal("999990000000000000000000");
  });
});
