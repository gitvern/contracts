# DAO Smart-contracts

Base smart-contracts for a DAO to derive theirs:

- Governance Token contracts
- Liquidity Building Auction (LBA) contracts using a UniSwap Liquidity Pool
- Treasury Budget distribution contracts using DAO tokens or ETH:
    - Hold the budget and distribute it through contributors based on work done
    - Or account work done IOUs for future claim when funds are allocated

### Demo contracts deployed to Rinkeby Testnet

Token deployed to: `0xC74496BcdCFdf69564d9f810832F7553Ff22696d`
Treasury deployed to: `0xaF4F12d94fb34220f15b72f41b2c6f74f8F836fd`

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
