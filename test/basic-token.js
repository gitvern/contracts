const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BasicToken", () => {
  let owner, addr1, BasicToken, token;

  const totalSupply = ethers.utils.parseEther('1000000');

  before(async () => {
    [owner, addr1] = await ethers.getSigners();

    BasicToken = await ethers.getContractFactory('BasicToken');
    token = await BasicToken.deploy(totalSupply);
    await token.deployed();
  });

  it("Should have correct name", async () => {
    expect(await token.name()).to.equal('DAO Token');
  });

  it("Should have correct symbol", async () => {
    expect(await token.symbol()).to.equal('DAO');
  });

  it("Should have 18 decimals", async () => {
    expect(await token.decimals()).to.equal(18);
  });

  it("Should have a correct total supply", async () => {
    expect(await token.totalSupply()).to.equal(totalSupply);
  });

  it("Should have all supply allocated to owner", async () => {
    expect(await token.balanceOf(owner.address)).to.equal(totalSupply);
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
