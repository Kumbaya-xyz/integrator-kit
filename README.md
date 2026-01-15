![Kumbaya Logo](https://github.com/Kumbaya-xyz/brand-assets/blob/main/logos/red/full-200.png?raw=true)

# Kumbaya DEX Integrator Kit

Integration resources for building on Kumbaya DEX - contract addresses, ABIs, and deployment information.

## Networks

### MegaETH Mainnet

- Chain ID: `4326`
- RPC: `https://mainnet.megaeth.com/rpc`
- Explorer: https://megaeth.blockscout.com/
- Pool init code hash: `0x851d77a45b8b9a205fb9f44cb829cceba85282714d2603d601840640628a3da7`

**Key Contracts**

| Contract                   | Address                                      |
| -------------------------- | -------------------------------------------- |
| UniswapV3Factory           | `0x68b34591f662508076927803c567Cc8006988a09` |
| NonfungiblePositionManager | `0x2b781C57e6358f64864Ff8EC464a03Fdaf9974bA` |
| SwapRouter02               | `0xE5BbEF8De2DB447a7432A47EBa58924d94eE470e` |
| UniversalRouter            | `0xAAB1C664CeaD881AfBB58555e6A3a79523D3e4C0` |
| QuoterV2                   | `0x1F1a8dC7E138C34b503Ca080962aC10B75384a27` |
| Permit2                    | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| WETH9                      | `0x4200000000000000000000000000000000000006` |

See `addresses/megaETH-mainnet.json` for all contracts.

### MegaETH Testnet

- Chain ID: `6343` (`0x18c7`)
- RPC: `https://carrot.megaeth.com/rpc`
- Explorer: https://megaeth-testnet-v2.blockscout.com/
- Pool init code hash: `0x851d77a45b8b9a205fb9f44cb829cceba85282714d2603d601840640628a3da7`

**Key Contracts**

| Contract                   | Address                                      |
| -------------------------- | -------------------------------------------- |
| UniswapV3Factory           | `0x53447989580f541bc138d29A0FcCf72AfbBE1355` |
| NonfungiblePositionManager | `0x367f9db1F974eA241ba046b77B87C58e2947d8dF` |
| SwapRouter02               | `0x8268DC930BA98759E916DEd4c9F367A844814023` |
| UniversalRouter            | `0x7E6c4Ada91e432efe5F01FbCb3492Bd3eb7ccD2E` |
| QuoterV2                   | `0xfb230b93803F90238cB03f254452bA3a3b0Ec38d` |
| Permit2                    | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| WETH9                      | `0x4200000000000000000000000000000000000006` |

See `addresses/megaETH-testnet.json` for all contracts.

## Directory Structure

```
integrator-kit/
├── addresses/           # Contract addresses by network
│   ├── megaETH-mainnet.json
│   └── megaETH-testnet.json
├── abis/                # Contract ABIs
├── scripts/             # Utility scripts
└── tests/               # Integration tests
    └── megaETH/         # Foundry tests for MegaETH (mainnet & testnet)
        └── ethereum-mainnet.json  # Uniswap reference for bytecode comparison
```

## ABIs Provided (source)

- Core: `UniswapV3Factory.json`, `UniswapV3Pool.json` (`@kumbaya_xyz/v3-core`)
- Periphery: `NonfungiblePositionManager.json`, `V3Migrator.json`, `TickLens.json`, `Multicall2.json`, `Multicall.json` (`@kumbaya_xyz/v3-periphery`)
- Swap Router: `QuoterV2.json`, `SwapRouter02.json` (`@kumbaya_xyz/swap-router-contracts`)
- Incentives: `UniswapV3Staker.json` (`@kumbaya_xyz/v3-staker`)
- Routing: `UniversalRouter.json` (`@kumbaya_xyz/universal-router`)
- Permits: `Permit2.json` (IPermit2 interface from permit2 lib)
- Tokens: `ERC20.json` (OpenZeppelin)

## Provenance

ABIs are extracted from Kumbaya contract build artifacts and verified against deployed bytecode on MegaETH.

## Regenerating ABIs

Use the fetch script to regenerate ABIs from Kumbaya build artifacts:

```bash
# Preview what would be fetched
npx tsx scripts/fetch-abis.ts --dry-run

# Fetch all ABIs
npx tsx scripts/fetch-abis.ts

# For Permit2, set your Etherscan API key (free at etherscan.io)
ETHERSCAN_API_KEY=your-key npx tsx scripts/fetch-abis.ts
```

The script sources ABIs from:
1. Kumbaya build artifacts (`../v3-core`, `../v3-periphery`, `../swap-router-contracts`, `../v3-staker`, `../universal-router`)
2. Etherscan mainnet for canonical Permit2 deployment
3. Block explorer fallback for verified contracts

## Bytecode Verification

Compare deployed Kumbaya contract bytecode against canonical Uniswap V3 on Ethereum mainnet. This masks out immutables (constructor args) to verify the logic is identical.

```bash
# Install dependencies
npm install @ethersproject/providers tsx

# Compare testnet deployment
npx tsx scripts/compare-bytecode.ts testnet

# Compare mainnet deployment
npx tsx scripts/compare-bytecode.ts mainnet
```

The script:
- Fetches bytecode from both Kumbaya (MegaETH) and Uniswap (Ethereum)
- Masks out constructor arguments / immutables
- Compares the remaining logic bytecode
- Verifies the correct `POOL_INIT_CODE_HASH` is embedded in each contract

## NPM Packages

Kumbaya publishes SDKs and contract packages for MegaETH integration:

### SDKs

| Package | Description |
|---------|-------------|
| [@kumbaya_xyz/sdk-core](https://www.npmjs.com/package/@kumbaya_xyz/sdk-core) | Core SDK with MegaETH chain definitions and token types |
| [@kumbaya_xyz/v3-sdk](https://www.npmjs.com/package/@kumbaya_xyz/v3-sdk) | V3 pool SDK with Kumbaya pool init code hash |
| [@kumbaya_xyz/router-sdk](https://www.npmjs.com/package/@kumbaya_xyz/router-sdk) | Router SDK for swap encoding |
| [@kumbaya_xyz/universal-router-sdk](https://www.npmjs.com/package/@kumbaya_xyz/universal-router-sdk) | Universal Router SDK |
| [@kumbaya_xyz/smart-order-router](https://www.npmjs.com/package/@kumbaya_xyz/smart-order-router) | Smart Order Router for optimal swap routing |

### Contracts

| Package | Description |
|---------|-------------|
| [@kumbaya_xyz/v3-core](https://www.npmjs.com/package/@kumbaya_xyz/v3-core) | V3 core contracts (Factory, Pool) |
| [@kumbaya_xyz/v3-periphery](https://www.npmjs.com/package/@kumbaya_xyz/v3-periphery) | V3 periphery contracts (NFTPositionManager, etc.) |
| [@kumbaya_xyz/v3-staker](https://www.npmjs.com/package/@kumbaya_xyz/v3-staker) | V3 liquidity mining staker |
| [@kumbaya_xyz/swap-router-contracts](https://www.npmjs.com/package/@kumbaya_xyz/swap-router-contracts) | SwapRouter02 and QuoterV2 contracts |
| [@kumbaya_xyz/universal-router](https://www.npmjs.com/package/@kumbaya_xyz/universal-router) | Universal Router contract |

### Other

| Package | Description |
|---------|-------------|
| [@kumbaya_xyz/default-token-list](https://www.npmjs.com/package/@kumbaya_xyz/default-token-list) | Curated token list for MegaETH |

### Installation Example

```bash
npm install @kumbaya_xyz/sdk-core @kumbaya_xyz/v3-sdk @kumbaya_xyz/smart-order-router
```

## On-Chain Integration Tests

The `tests/megaETH/` directory contains Foundry-based integration tests that run against the deployed contracts on MegaETH. These tests verify:

- **Contract Deployment**: All core contracts are deployed and accessible
- **CREATE2 Pool Addresses**: The pool init code hash correctly computes pool addresses matching what the factory creates
- **Periphery Integration**: QuoterV2, SwapRouter02, and NFTPositionManager can find and interact with pools
- **Full Stack Consistency**: End-to-end verification that all components agree on pool addresses

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Access to MegaETH Testnet RPC

### Running the Tests

```bash
cd tests/megaETH

# Install dependencies
forge install

# Run tests against MegaETH Testnet
forge test --rpc-url https://carrot.megaeth.com/rpc -vvv

# Run tests against MegaETH Mainnet
forge test --rpc-url https://mainnet.megaeth.com/rpc -vvv
```

### Test Coverage

| Test | Description |
|------|-------------|
| `test_AllContractsDeployed` | Verifies all core contracts have code |
| `test_FactoryFeeAmounts` | Checks fee tier configurations (100, 500, 3000, 10000) |
| `test_PoolInitCodeHash_*` | Validates CREATE2 address computation matches factory |
| `test_NewPoolMatchesCREATE2` | Creates a new pool and verifies address matches pre-computed |
| `test_QuoterV2_PoolAddressComputation` | Confirms QuoterV2 can find and quote pools |
| `test_FullStack_PoolAddressConsistency` | End-to-end verification of all components |
| `test_WrapETH` / `test_UnwrapWETH` | WETH9 deposit/withdraw functionality |
| `test_QuoteSwap` | Get a quote for WETH -> USDC swap |

### Verifying Pool Init Code Hash

The tests use the Kumbaya pool init code hash to compute pool addresses via CREATE2:

```solidity
bytes32 constant POOL_INIT_CODE_HASH = 0x851d77a45b8b9a205fb9f44cb829cceba85282714d2603d601840640628a3da7;
```

If you're integrating with Kumbaya DEX, ensure your SDK/code uses this hash instead of the default Uniswap hash.
