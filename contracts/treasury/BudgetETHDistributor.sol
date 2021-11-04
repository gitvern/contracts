// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact security@gitvern.org
contract BudgetETHDistributor is Pausable, Ownable {

    event BudgetDeposited(address indexed from, uint256 weiAmount);
    event BudgetWithdrawn(address indexed to, uint256 weiAmount);
    event RewardsAssigned(address indexed contributor, uint256 weiAmount);
    event RewardsReversed(address indexed contributor, uint256 weiAmount);
    event RewardsReleased(address indexed contributor, uint256 weiAmount);

    address private _manager;
    mapping(address => uint256) private _rewards;
    uint256 private _assigned;
    uint256 private _released;


    constructor() {
        _assignManager(msg.sender);
    }

    receive() external payable {
        emit BudgetDeposited(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function availableBudget() public view returns (uint256) {
        return address(this).balance - _assigned;
    }

    function withdraw(address payable wallet) public onlyOwner {
        uint256 balance = availableBudget();
        require(balance > 0 && balance <= address(this).balance, "No withdrawable balance");

        (bool success, ) = wallet.call{value: balance}("");
        require(success, "Withdrawal transfer failed");

        emit BudgetWithdrawn(wallet, balance);
    }

    function assignManager(address newManager) public onlyOwner {
        require(newManager != address(0), "Cannot assign manager to the zero address");
        _assignManager(newManager);
    }

    function _assignManager(address newManager) internal {
        _manager = newManager;
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(manager() == msg.sender, "Caller is not the assigned manager");
        _;
    }

    function rewardsOf(address contributor) public view returns (uint256) {
        return _rewards[contributor];
    }

    function rewardsAssigned() public view returns (uint256) {
        return _assigned;
    }

    function rewardsReleased() public view returns (uint256) {
        return _released;
    }

    function assign(address contributor, uint256 weiAmount) public onlyManager whenNotPaused {
        require(contributor != address(0), "Invalid contributor address");
        require(weiAmount > 0 && weiAmount <= availableBudget(), "Invalid amount to assign");

        _rewards[contributor] += weiAmount;
        _assigned += weiAmount;

        emit RewardsAssigned(contributor, weiAmount);
    }

    function reverse(address contributor, uint256 weiAmount) public onlyManager whenNotPaused {
        require(contributor != address(0), "Invalid contributor address");
        require(weiAmount > 0 && weiAmount <= rewardsOf(contributor), "Invalid amount to reverse");

        _rewards[contributor] -= weiAmount;
        _assigned -= weiAmount;

        emit RewardsReversed(contributor, weiAmount);
    }

    function release(address payable contributor, uint256 weiAmount) public onlyManager whenNotPaused {
        require(contributor != address(0), "Invalid contributor address");
        require(weiAmount > 0 && weiAmount <= rewardsOf(contributor), "Invalid amount to release");

        _rewards[contributor] -= weiAmount;
        _assigned -= weiAmount;
        _released += weiAmount;

        (bool success, ) = contributor.call{value: weiAmount}("");
        require(success, "Rewards release transfer failed");

        emit RewardsReleased(contributor, weiAmount);
    }
}