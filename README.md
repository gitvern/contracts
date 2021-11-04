# DAO Smart-contracts

Base smart-contracts for a DAO to derive theirs:

- Governance Token contracts
- Liquidity Building Auction (LBA) contracts using a UniSwap Liquidity Pool
- Development Treasury contracts using DAO and LP tokens

## What is an LBA?

It's the marriage between a Dutch Auction token sale and UniSwap Liquidity Providing. Instead of conducting a token sale with large chunks of tokens being reserved to the DAO treasury, dutch auctions tend to result in a fairer way of finding the token price. Then instead of just selling the tokens, in a LBA the result of it is a position on the UniSwap Liquidity Pool for each participant, and a matching aggregated position to the DAO treasury.

### What makes an LBA different from an ICO?

- In an ICO the participant exchanges liquid assets for mostly illiquid assets, that usually have very difficult exit if things go south, and in an LBA the LP position is mostly liquid and generates yield, while conferring governance access at the same time

- In an LBA there's a balance between treasury pools and the liquidity providers capital, also creating more transparency between the DAO and it's participants, meaning that it is easier to figure out if the liquidity is decreasing at a fast pace and opt out before it's too late

- As UniSwap Liquidity Pools are balanced, when the DAO needs to spend from it's treasury it has to remove liquidity from the pool, meaning that a corresponding amount of tokens and base currency (ETH) is always the result

- This means that interesting models can be built around DAO budgets, for instance, that could require that the distribution that takes place to incentivise participants work in the DAO is made only in the DAO token, enforcing a token buy back for every period's budget, causing buy pressure that can minimize the opposite sell pressure from the participants that need to cash out

- In an ICO the token price is fixed, and usually favours the early, as in an LBA dutch auction all participants get the same token price, and it is defined by all the participants valid bids, so making the accessibility more fair and even

- ...

## This is a hardhat project

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

### Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
