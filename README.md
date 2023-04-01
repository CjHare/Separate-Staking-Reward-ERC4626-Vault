# Simple-Rewarding-Vault
A [OpenZepplin ERC4626](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/1a60b061d5bb809c3d7e4ee915c77a00b1eca95d/contracts/token/ERC20/extensions/ERC4626.sol) Vault that hands out rewards in the vein of [Masterchef V2](https://github.com/sushiswap/sushiswap/blob/b0855be0a73ff3e69aab3216e1a381a0d79d0f2d/protocols/masterchef/contracts/MasterChefV2.sol)


## Setup

### Install

To retrieve the project dependencies and before any further tasks will run correctly

```shell
npm ci
```

#### Build and Test

```shell
npm run build
npm test
```

#### Formatting
To run both the TypeScript and Solidity source formatters.
```shell
npm run format
```

#### Linting
To run both the TypeScript and Solidity linters.
```shell
npm run lint
```

## Tools

Setup and run instructions:

- [Slither](./docs/tools/slither.md); Trail of Bits Solidity static analyzer.
