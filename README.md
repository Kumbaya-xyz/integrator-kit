![Kumbaya Logo](https://github.com/Kumbaya-xyz/brand-assets/blob/main/logos/red/full-200.png?raw=true)

# Kumbaya DEX Integrator Kit

Integration resources for building on Kumbaya DEX - contract addresses, ABIs, and deployment information.

## Networks

### MegaETH Testnet (v2)

- Chain ID: `6343` (`0x18c7`)
- RPC: `https://timothy.megaeth.com/rpc`
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

See `addresses.json` for supporting contracts (Multicall2, TickLens, V3Migrator, V3Staker, descriptors, ProxyAdmin).

## ABIs Provided (source)

- Core: `UniswapV3Factory.json`, `UniswapV3Pool.json` (`@kumbaya_xyz/v3-core`)
- Periphery: `NonfungiblePositionManager.json`, `V3Migrator.json`, `TickLens.json`, `Multicall2.json` (`@kumbaya_xyz/v3-periphery`)
- Swap Router: `QuoterV2.json`, `SwapRouter02.json` (`@kumbaya_xyz/swap-router-contracts`)
- Incentives: `UniswapV3Staker.json` (`@kumbaya_xyz/v3-staker`)
- Routing: `UniversalRouter.json` (`@kumbaya_xyz/universal-router`)
- Permits: `Permit2.json` (IPermit2 interface from permit2 lib)
- Tokens: `ERC20.json` (OpenZeppelin)

## Provenance

ABIs are extracted from Kumbaya contract build artifacts and verified against deployed bytecode on MegaETH testnet.

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

## MegaETH Mainnet Deployment

- Chain ID: `4326`
- RPC / Explorer: _(not provided)_

### Key Contracts (from `mainnetAddresses.json`)

| Contract                                      | Address                                      |
| --------------------------------------------- | -------------------------------------------- |
| `UniswapV3Factory`                            | `TBA` |
| `NonfungiblePositionManager`                  | `TBA` |
| `SwapRouter02`                                | `TBA` |
| `UniversalRouter`                             | `TBA` |
| `QuoterV2`                                    | `TBA` |
| `UnsupportedProtocol`                         | `TBA` |
| `Multicall2`                                  | `TBA` |
| `ProxyAdmin`                                  | `TBA` |
| `TickLens`                                    | `TBA` |
| `NFTDescriptor (v1.3.0)`                      | `TBA` |
| `NonfungibleTokenPositionDescriptor (v1.3.0)` | `TBA` |
| `DescriptorProxy`                             | `TBA` |
| `V3Migrator`                                  | `TBA` |
| `UniswapV3Staker`                             | `TBA` |
