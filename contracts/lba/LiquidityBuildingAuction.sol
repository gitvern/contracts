// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IUniswapV2Router02.sol";


/// @custom:security-contact security@gitvern.org
contract LiquidityBuildingAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants
     */
    uint constant public MAX_TOKENS_SOLD = 1000000 * 10**18; // 1M
    uint constant public WAITING_PERIOD = 7 days;
    address constant routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    /*
     *  Storage
     */
    IERC20 public token;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage, "Contract not in expected state");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Only owner is allowed to proceed");
        _;
    }

    modifier isWallet() {
        require(msg.sender == wallet, "Only wallet is allowed to proceed");
        _;
    }

    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36, "Invalid payload");
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && block.timestamp > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

    /*
     *  Public functions
     */
     
    /// @dev Contract constructor function sets owner
    /// @param _wallet DAO treasury wallet
    /// @param _ceiling Auction ceiling
    /// @param _priceFactor Auction price factor
    constructor(address _wallet, uint _ceiling, uint _priceFactor)
    {
        require(_wallet != address(0) && _ceiling != 0 && _priceFactor != 0, "Constructor arguments cannot be null");
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

    /// @dev Setup function sets external contracts' addresses
    /// @param _token DAO Governance token address
    function setup(address _token)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
        // Validate token balance
        require(token.balanceOf(address(this)) == MAX_TOKENS_SOLD, "Incorrect token balance");
        stage = Stages.AuctionSetUp;
    }

    /// @dev Starts auction and sets startBlock
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started
    /// @param _ceiling Updated auction ceiling
    /// @param _priceFactor Updated start price factor
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }

    /// @dev Calculates current token price
    /// @return Returns token price
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet
    /// @return Returns current auction stage
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction
    /// @param receiver Bid will be assigned to this address if set
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set.
        if (receiver == address(0))
            receiver = msg.sender;
        
        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.
        uint maxWei = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        // Only invest maximum possible amount.
        amount = (maxWei <= msg.value) ? maxWei : msg.value;
        require(amount > 0, "Has to provide eth with bid");
        // Save the bid
        bids[receiver] += amount;
        totalReceived += amount;
        // When maxWei is equal to the eth amount the auction is ended and finalizeAuction is triggered.
        if (maxWei == msg.value) finalizeAuction();
        bool success;
        // Forward funding to ether wallet
        (success, ) = wallet.call{value: amount}("");
        require(success, "Sending auction funds failed");
        // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
        (success, ) = receiver.call{value: msg.value - amount}("");
        require(success, "Sending change back failed");

        emit BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction
    /// @param receiver Tokens will be assigned to this address if set
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == address(0))
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        token.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price
    /// @return Returns stop price
    function calcStopPrice()
        view
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }

    /// @dev Calculates token price
    /// @return Returns token price
    function calcTokenPrice()
        view
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        // Auction contract transfers all unsold tokens to DAO treasury wallet
        token.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
        endTime = block.timestamp;
    }

    function addLiquidity(uint256 amount)
        internal
    {
        IUniswapV2Router02 uniRouter = IUniswapV2Router02(routerAddress);
        // Approve router
        token.approve(routerAddress, amount);
        // add the liquidity
        uniRouter.addLiquidityETH{value: msg.value}(
            address(token),
            amount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}