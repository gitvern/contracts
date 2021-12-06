const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BudgetETHDistributor", () => {
  let owner, manager, contrib1, contrib2, provider, BudgetETHDistributor, treasury;

  const testBudget = ethers.utils.parseEther("50");
  const testRewards = ethers.utils.parseEther("1");

  before(async () => {
    [owner, manager, contrib1, contrib2] = await ethers.getSigners();
    
    provider = owner.provider;

    BudgetETHDistributor = await ethers.getContractFactory("BudgetETHDistributor");
    treasury = await BudgetETHDistributor.deploy();
    await treasury.deployed();
  });

  it("Should have no budget", async () => {
    expect(await treasury.availableBudget()).to.equal(0);
  });

  it("Should revert when trying to withdraw", async () => {
    expect(treasury.withdraw(owner.address)).to.be.revertedWith("No withdrawable balance");
  });

  it("Manager should initially be the owner", async () => {
    expect(await treasury.manager()).to.equal(owner.address);
  });

  it("Should only allow the owner to set another manager", async () => {
    await expect(treasury.connect(contrib1).assignManager(manager.address)).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(await treasury.assignManager(manager.address)).to.be.ok;
    await expect(await treasury.manager()).to.equal(manager.address);
    await expect(treasury.connect(manager).assignManager(contrib1.address)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should revert assign manager if passed an invalid address", async () => {
    expect(treasury.assignManager("0x0000000000000000000000000000000000000000")).to.be.revertedWith("Invalid manager address");
  });

  it("Should be able to receive a rewards budget", async () => {
    await expect(await owner.sendTransaction({to: treasury.address, value: testBudget})).to.changeEtherBalances([owner, treasury], [testBudget.mul(-1), testBudget]);
    await expect(await treasury.availableBudget()).to.equal(testBudget);
  });

  it("Should only allow the manager to assign rewards", async () => {
    await expect(treasury.assign(contrib1.address, testRewards)).to.be.revertedWith("Not the assigned manager");
    await expect(treasury.connect(contrib1).assign(contrib1.address, testRewards)).to.be.revertedWith("Not the assigned manager");
    await expect(await treasury.connect(manager).assign(contrib1.address, testRewards)).to.emit(treasury, "RewardsAssigned").withArgs(contrib1.address, testRewards);
    await expect(await treasury.rewardsAssigned()).to.equal(testRewards);
    await expect(await treasury.availableBudget()).to.equal(testBudget.sub(testRewards));
    await expect(await provider.getBalance(treasury.address)).to.equal(testBudget);
  });

  it("Anyone should be able to examine the rewards assigned to a contributor", async () => {
    await expect(await treasury.connect(contrib2.address).rewardsOf(contrib1.address)).to.equal(testRewards);
  });
  
  it("Manager shouldn't be allowed to assign rewards larger than available budget", async () => {
    await expect(treasury.connect(manager).assign(contrib2.address, testBudget)).to.be.revertedWith("Invalid amount to assign");
  });

  it("Manager should be able to assign more rewards to the same contributor", async () => {
    await expect(await treasury.connect(manager).assign(contrib1.address, testRewards)).to.emit(treasury, "RewardsAssigned").withArgs(contrib1.address, testRewards);
    await expect(await treasury.rewardsOf(contrib1.address)).to.equal(testRewards.mul(2));
    await expect(await treasury.rewardsAssigned()).to.equal(testRewards.mul(2));
    await expect(await treasury.availableBudget()).to.equal(testBudget.sub(testRewards.mul(2)));
    await expect(await provider.getBalance(treasury.address)).to.equal(testBudget);
  });

  it("Manager should be able to assign rewards to a different contributor as well", async () => {
    await expect(await treasury.connect(manager).assign(contrib2.address, testRewards)).to.emit(treasury, "RewardsAssigned").withArgs(contrib2.address, testRewards);
    await expect(await treasury.rewardsOf(contrib1.address)).to.equal(testRewards.mul(2));
    await expect(await treasury.rewardsOf(contrib2.address)).to.equal(testRewards);
    await expect(await treasury.rewardsAssigned()).to.equal(testRewards.mul(3));
    await expect(await treasury.availableBudget()).to.equal(testBudget.sub(testRewards.mul(3)));
    await expect(await provider.getBalance(treasury.address)).to.equal(testBudget);
  });

  it("Should only allow the manager to reverse assigned rewards to a contributor", async () => {
    await expect(treasury.reverse(contrib1.address, testRewards)).to.be.revertedWith("Not the assigned manager");
    await expect(treasury.connect(contrib1).reverse(contrib1.address, testRewards)).to.be.revertedWith("Not the assigned manager");
    await expect(await treasury.connect(manager).reverse(contrib2.address, testRewards)).to.emit(treasury, "RewardsReversed").withArgs(contrib2.address, testRewards);
    await expect(await treasury.connect(manager).reverse(contrib1.address, testRewards)).to.emit(treasury, "RewardsReversed").withArgs(contrib1.address, testRewards);
    await expect(await treasury.rewardsOf(contrib1.address)).to.equal(testRewards);
    await expect(await treasury.rewardsOf(contrib2.address)).to.equal(0);
    await expect(await treasury.rewardsAssigned()).to.equal(testRewards);
    await expect(await treasury.availableBudget()).to.equal(testBudget.sub(testRewards));
    await expect(await provider.getBalance(treasury.address)).to.equal(testBudget);
  });

  it("Manager shouldn't be able to reverse more than the assigned rewards to a contributor", async () => {
    await expect(treasury.connect(manager).reverse(contrib2.address, testRewards)).to.be.revertedWith("Invalid amount to reverse");
  });

  it("Should only allow the manager to release assigned rewards to a contributor", async () => {
    await expect(treasury.release(contrib1.address, testRewards)).to.be.revertedWith("Not the assigned manager");
    await expect(treasury.connect(contrib1).release(contrib1.address, testRewards)).to.be.revertedWith("Not the assigned manager");
    await expect(await treasury.connect(manager).release(contrib1.address, testRewards)).to.emit(treasury, "RewardsReleased").withArgs(contrib1.address, testRewards);
    await expect(await treasury.rewardsOf(contrib1.address)).to.equal(0);
    await expect(await treasury.rewardsAssigned()).to.equal(0);
    await expect(await treasury.rewardsReleased()).to.equal(testRewards);
    await expect(await treasury.availableBudget()).to.equal(testBudget.sub(testRewards));
    await expect(await provider.getBalance(treasury.address)).to.equal(testBudget.sub(testRewards));
  });

  it("Manager shouldn't be able to release invalid reward amounts", async () => {
    expect(treasury.connect(manager).release(contrib1.address, testRewards)).to.be.revertedWith("Invalid amount to release");
  });

  it("Shouldn't allow any manager operations if passed an invalid address", async () => {
    expect(treasury.connect(manager).assign("0x0000000000000000000000000000000000000000", testRewards)).to.be.revertedWith("Invalid contributor address");
    expect(treasury.connect(manager).reverse("0x0000000000000000000000000000000000000000", testRewards)).to.be.revertedWith("Invalid contributor address");
    expect(treasury.connect(manager).release("0x0000000000000000000000000000000000000000", testRewards)).to.be.revertedWith("Invalid contributor address");
  });

  it("Should only allow owner to withdraw remaining balance from contract", async () => {
    await expect(treasury.connect(manager).withdraw(manager.address)).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(treasury.connect(contrib1).withdraw(manager.address)).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(await treasury.withdraw(owner.address)).to.emit(treasury, "BudgetWithdrawn").withArgs(owner.address, testBudget.sub(testRewards));
    await expect(await treasury.availableBudget()).to.equal(0);
    await expect(await provider.getBalance(treasury.address)).to.equal(0);
  });

  it("Should only allow owner to pause the contract", async () => {
    await expect(treasury.connect(manager).pause()).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(treasury.connect(contrib1).pause()).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(await treasury.pause()).to.emit(treasury, "Paused");
  });

  it("Shouldn't allow any manager operations when paused", async () => {
    await expect(treasury.connect(manager).assign(contrib1.address, testRewards)).to.be.revertedWith("Pausable: paused");
    await expect(treasury.connect(manager).reverse(contrib1.address, testRewards)).to.be.revertedWith("Pausable: paused");
    await expect(treasury.connect(manager).release(contrib1.address, testRewards)).to.be.revertedWith("Pausable: paused");
  });

  it("Should only allow owner to unpause the contract", async () => {
    await expect(treasury.connect(manager).unpause()).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(treasury.connect(contrib1).unpause()).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(await treasury.unpause()).to.emit(treasury, "Unpaused");
  });
});
