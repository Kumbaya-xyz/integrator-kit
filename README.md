# Kumbaya DEX Integrator Info

## Networks

### MegaETH Testnet (v2)

- Chain ID: `6343` (`0x18c7`)
- RPC: `https://timothy.megaeth.com/rpc`
- Explorer: https://megaeth-testnet-v2.blockscout.com/
- Pool init code hash: `0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54`

**Key Contracts**

| Contract                   | Address                                      |
| -------------------------- | -------------------------------------------- |
| UniswapV3Factory           | `0x619fb6C12c36b57a8bAb05e98F42C43745DCf69f` |
| NonfungiblePositionManager | `0xa204A97EF8Bd2E3198f19EB5a804680467BD85f5` |
| SwapRouter02               | `0xE060C6412Cb9E3C85dDdED44AAd1DC9fAFfb5cD9` |
| UniversalRouter            | `0xCdd0a5Ac12820AC7299b72Dc2126687895267298` |
| QuoterV2                   | `0x49D39c2Ca480F8C1e2a623E457756b237EB07a4b` |
| Permit2                    | `0x2D11a87b78258fD3a246eDd1E37B6779451Ff111` |
| WETH9                      | `0x4200000000000000000000000000000000000006` |

See `addresses.json` for supporting contracts (Multicall2, TickLens, V3Migrator, V3Staker, descriptors, ProxyAdmin).

## ABIs Provided (source)

- Core: `UniswapV3Factory.json`, `UniswapV3Pool.json` (`@uniswap/v3-core@1.0.0`)
- Periphery: `QuoterV2.json`, `SwapRouter02.json`, `NonfungiblePositionManager.json`, `V3Migrator.json`, `TickLens.json`, `Multicall2.json` (`@uniswap/v3-periphery@1.4.x`)
- Incentives: `UniswapV3Staker.json` (`@uniswap/v3-staker@1.0.0`)
- Tokens: `ERC20.json`
- Permits and routing: `Permit2.json` (`@uniswap/permit2` artifact), `UniversalRouter.json` (`@uniswap/universal-router@2.0.0`)

## Provenance

- ABIs are trimmed to ABI-only output from the official Uniswap packages listed above.

## MegaETH Mainnet Deployment

- Chain ID: `4326`
- RPC / Explorer: _(not provided)_

### Key Contracts (from `mainnetAddresses.json`)

| Contract                                      | Address                                      |
| --------------------------------------------- | -------------------------------------------- |
| `UniswapV3Factory`                            | `0xf2e46138d197602CFCc8B1Dd0284DF09EfD333A3` |
| `NonfungiblePositionManager`                  | `0x8bd2974FcA79BbadC5Cb4E452F505E0Be6Ea740c` |
| `SwapRouter02`                                | `0x6A4A9D98C3bC9B94A07A46bD2ecD12c055C4B7B8` |
| `UniversalRouter`                             | `0x862bf267C4bD1d5ce83bCc9daecE4d6570bf5338` |
| `QuoterV2`                                    | `0xfb3Eb7CAb0a8fAA4bB82c733CF527E927925b960` |
| `UnsupportedProtocol`                         | `0x6D7c320d076F59ca7ABa12bf9C7a20827D073c3a` |
| `Multicall2`                                  | `0xA9AEDC1CD2b734760F2268fe9ECA6f8C1A5B899D` |
| `ProxyAdmin`                                  | `0x9802270F8a9d2edfD549b5f1c4B119233983D945` |
| `TickLens`                                    | `0xB18Bfe5ff3Bc9C6619ca4F100192d0Bc110d2468` |
| `NFTDescriptor (v1.3.0)`                      | `0x2CCBc45d87E57EF4dcFAABFF321F93E1d1c2ed97` |
| `NonfungibleTokenPositionDescriptor (v1.3.0)` | `0x9930d2308D8787103191e1903D96ac2Fd0dBBe23` |
| `DescriptorProxy`                             | `0xa7D469B1128b5Cd7779b78ee0bf7484df5b3d37f` |
| `V3Migrator`                                  | `0xa2b291651DE6EA0B67fD32DFdC31541A34064ac0` |
| `UniswapV3Staker`                             | `0x5E55b2c0094FD2158B12C9DcDaEbD6E5221Beb1F` |
