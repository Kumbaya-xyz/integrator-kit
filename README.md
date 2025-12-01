# Kumbaya DEX Integrator Info

## Network

- Chain: MegaETH Testnet (`6343`, hex `0x18c7`)
- RPC: `https://timothy.megaeth.com/rpc`
- Explorer: https://megaeth-testnet-v2.blockscout.com/
- Pool init code hash: `0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54`

## Key Contracts

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
