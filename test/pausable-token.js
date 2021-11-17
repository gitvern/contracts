const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PausableToken", () => {
  let owner, addr1, PausableToken, token;

  const initialSupply = ethers.utils.parseEther("1000000");

  before(async () => {
    [owner, addr1] = await ethers.getSigners();

    PausableToken = await ethers.getContractFactory("PausableToken");
    token = await PausableToken.deploy(initialSupply);
    await token.deployed();
  });

  it("Should have correct name", async () => {
    await expect(await token.name()).to.equal('DAO Token');
  });

  it("Should have correct symbol", async () => {
    await expect(await token.symbol()).to.equal('DAO');
  });

  it("Should have 18 decimals", async () => {
    await expect(await token.decimals()).to.equal(18);
  });

  it("Should have a correct total supply", async () => {
    await expect(await token.totalSupply()).to.equal(initialSupply);
  });

  it("Should have all supply allocated to owner", async () => {
    await expect(await token.balanceOf(owner.address)).to.equal(initialSupply);
  });

  it("Others shouldn't be able to pause token transfers", async () => {
    await expect(token.connect(addr1).pause()).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it("Owner should be able to pause token transfers", async () => {
    await expect(token.pause()).to.emit(token, 'Paused');
  });

  it("Shouldn't be able to transfer tokens while paused", async () => {
    const value = ethers.utils.parseEther('10');

    await expect(token.transfer(addr1.address, value)).to.be.revertedWith('Pausable: paused');
  });

  it("Others shouldn't be able to unpause token transfers", async () => {
    await expect(token.connect(addr1).unpause()).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it("Owner should be able to unpause token transfers", async () => {
    await expect(token.unpause()).to.emit(token, 'Unpaused');
  });

  it("Should be able to transfer tokens to another account", async () => {
    const value = ethers.utils.parseEther('10');

    await expect(() =>
      expect(token.transfer(addr1.address, value))
      .to.emit(token, 'Transfer').withArgs(owner.address, addr1.address, value))
      .to.changeTokenBalances(token, [owner, addr1], [value.mul(-1), value]);
  });

  it("Shouldn't be able to transfer more tokens than account owns", async () => {
    const value = ethers.utils.parseEther('11');

    await expect(token.connect(addr1).transfer(owner.address, value)).to.be.revertedWith('ERC20: transfer amount exceeds balance');
  });
});
