// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact security@gitvern.org
contract BudgetDAODistributor is Pausable, Ownable {
    using SafeERC20 for IERC20;

    event BudgetWithdrawn(address indexed to, uint256 weiAmount);
    event RewardsAssigned(address indexed contributor, uint256 weiAmount);
    event RewardsReversed(address indexed contributor, uint256 weiAmount);
    event RewardsReleased(address indexed contributor, uint256 weiAmount);

    address private _token;
    address private _manager;
    mapping(address => uint256) private _rewards;
    uint256 private _assigned;
    uint256 private _released;


    constructor(address budgetToken) {
        require(budgetToken != address(0), "Invalid budget token address");
        _token = budgetToken;
        _assignManager(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function token() public view returns (address) {
        return _token;
    }

    function availableBudget() public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) - _assigned;
    }

    function withdraw(address payable wallet) public onlyOwner {
        uint256 balance = availableBudget();
        require(balance > 0 && balance <= IERC20(_token).balanceOf(address(this)), "No withdrawable balance");

        // require(IERC20(_token).transfer(wallet, balance), "Withdrawal transfer failed");
        IERC20(_token).safeTransfer(wallet, balance);

        emit BudgetWithdrawn(wallet, balance);
    }

    function assignManager(address newManager) public onlyOwner {
        require(newManager != address(0), "Invalid manager address");
        _assignManager(newManager);
    }

    function _assignManager(address newManager) internal {
        _manager = newManager;
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(manager() == msg.sender, "Not the assigned manager");
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

        // require(IERC20(_token).transfer(contributor, weiAmount), "Rewards release transfer failed");
        IERC20(_token).safeTransfer(contributor, weiAmount);

        emit RewardsReleased(contributor, weiAmount);
    }
}