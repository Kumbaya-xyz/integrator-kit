/**
 * Bytecode Comparison Script
 *
 * Compares deployed Kumbaya contract bytecode against canonical Uniswap V3 on Ethereum mainnet.
 * Masks out immutables (constructor args) to verify the logic is identical.
 *
 * Usage:
 *   npx tsx scripts/compare-bytecode.ts testnet   # Compare MegaETH testnet
 *   npx tsx scripts/compare-bytecode.ts mainnet   # Compare MegaETH mainnet
 */

import { StaticJsonRpcProvider } from '@ethersproject/providers'
import { readFileSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))

// RPC endpoints
const RPC_ENDPOINTS: Record<string, string> = {
  testnet: 'https://timothy.megaeth.com/rpc',
  mainnet: '', // TBA
  ethereum: 'https://eth.llamarpc.com',
}

// POOL_INIT_CODE_HASH values
const KUMBAYA_POOL_INIT_CODE_HASH = '851d77a45b8b9a205fb9f44cb829cceba85282714d2603d601840640628a3da7'
const UNISWAP_POOL_INIT_CODE_HASH = 'e34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54'

// Canonical Uniswap V3 contracts on Ethereum mainnet
const UNISWAP_CONTRACTS: Record<string, string> = {
  UniswapV3Factory: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
  Multicall2: '0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696',
  ProxyAdmin: '0xB753548F6E010e7e680BA186F9Ca1BdAB2E90cf2',
  TickLens: '0xbfd8137f7d1516D3ea5cA83523914859ec47F573',
  NonfungibleTokenPositionDescriptor: '0x91ae842A5Ffd8d12023116943e72A606179294f3',
  NonfungiblePositionManager: '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
  V3Migrator: '0xA5644E29708357803b5A882D272c41cC0dF92B34',
  UniswapV3Staker: '0xe34139463bA50bD61336E0c446Bd8C0867c6fE65',
  QuoterV2: '0x61fFE014bA17989E743c5F6cB21bF9697530B21e',
  SwapRouter02: '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
  UniversalRouter: '0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af',
}

// Uniswap immutables (Ethereum mainnet)
const UNISWAP_IMMUTABLES: Record<string, string[]> = {
  UniswapV3Factory: [
    '1f98431c8ad98523631ae4a59f267346ea31f984', // self
  ],
  NonfungiblePositionManager: [
    '1f98431c8ad98523631ae4a59f267346ea31f984', // factory
    'c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH9
    'ee6a57ec80ea46401049e92587e52f5ec1c24785', // tokenDescriptor
    UNISWAP_POOL_INIT_CODE_HASH,
  ],
  UniswapV3Staker: [
    '1f98431c8ad98523631ae4a59f267346ea31f984', // factory
    'c36442b4a4522e871399cd717abdd847ab11fe88', // nftPositionManager
    UNISWAP_POOL_INIT_CODE_HASH,
  ],
  QuoterV2: [
    '1f98431c8ad98523631ae4a59f267346ea31f984', // factory
    'c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH9
    UNISWAP_POOL_INIT_CODE_HASH,
  ],
  SwapRouter02: [
    '1f98431c8ad98523631ae4a59f267346ea31f984', // factory (v3)
    'c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH9
    '5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f', // v2 factory
    'c36442b4a4522e871399cd717abdd847ab11fe88', // nftPositionManager
    UNISWAP_POOL_INIT_CODE_HASH,
  ],
  NonfungibleTokenPositionDescriptor: [
    'c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH9
    '42b24a95702b9986e82d421cc3568932790a48ec', // nftDescriptor library
  ],
  V3Migrator: [
    '1f98431c8ad98523631ae4a59f267346ea31f984', // factory
    'c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH9
    'c36442b4a4522e871399cd717abdd847ab11fe88', // nftPositionManager
    UNISWAP_POOL_INIT_CODE_HASH,
  ],
  UniversalRouter: [
    '000000000022d473030f116ddee9f6b43ac78ba3', // permit2
    'c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', // WETH9
    '1f98431c8ad98523631ae4a59f267346ea31f984', // v3Factory
    'c36442b4a4522e871399cd717abdd847ab11fe88', // v3NFTPositionManager
    '5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f', // v2Factory
    '000000000004444c5dc75cb358380d2e3de08a90', // v4PoolManager
    '00000000bd216513d74c8cf14cf4747e6aaa6420', // v4PositionManager
    UNISWAP_POOL_INIT_CODE_HASH,
    '96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f', // V2 PAIR_INIT_CODE_HASH
  ],
}

// Addresses in Uniswap bytecode to replace with zeros (where Kumbaya uses 0x0)
const UNISWAP_ADDRESSES_TO_ZERO: Record<string, string[]> = {
  SwapRouter02: [
    '5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f', // Uniswap v2 factory
  ],
  UniversalRouter: [
    '000000000004444c5dc75cb358380d2e3de08a90', // Uniswap v4PoolManager
    '00000000bd216513d74c8cf14cf4747e6aaa6420', // Uniswap v4PositionManager
    '5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f', // Uniswap v2Factory
  ],
}

// Contracts with expected differences due to different compilation or features
const CONTRACTS_WITH_EXPECTED_DIFFERENCES: Record<string, string> = {
  UniswapV3Factory: 'Minor difference in fee tier encoding (0x02 vs 0x04)',
  UniversalRouter: 'Different size due to V4 placeholder handling and UnsupportedProtocol pattern',
}

// Load addresses from JSON file
function loadAddresses(network: 'testnet' | 'mainnet'): { rpc: string; contracts: Record<string, string>; poolInitCodeHash: string } {
  const filename = network === 'testnet' ? 'addresses.json' : 'mainnetAddresses.json'
  const filepath = join(__dirname, '..', filename)
  const data = JSON.parse(readFileSync(filepath, 'utf-8'))

  return {
    rpc: data.rpc || RPC_ENDPOINTS[network],
    contracts: data.contracts,
    poolInitCodeHash: data.poolInitCodeHash?.replace('0x', '') || KUMBAYA_POOL_INIT_CODE_HASH,
  }
}

// Build Kumbaya immutables based on loaded addresses
function buildKumbayaImmutables(contracts: Record<string, string>, poolInitCodeHash: string): Record<string, string[]> {
  const weth = contracts.WETH9?.toLowerCase().replace('0x', '') || '4200000000000000000000000000000000000006'
  const factory = contracts.UniswapV3Factory?.toLowerCase().replace('0x', '')
  const nftManager = contracts.NonfungiblePositionManager?.toLowerCase().replace('0x', '')
  const descriptorProxy = contracts.DescriptorProxy?.toLowerCase().replace('0x', '')
  const descriptorLib = contracts.NonfungibleTokenDescriptorLibrary?.toLowerCase().replace('0x', '')
  const permit2 = contracts.Permit2?.toLowerCase().replace('0x', '') || '000000000022d473030f116ddee9f6b43ac78ba3'

  return {
    UniswapV3Factory: factory ? [factory] : [],
    NonfungiblePositionManager: [
      factory,
      weth,
      descriptorProxy,
      poolInitCodeHash,
    ].filter(Boolean) as string[],
    UniswapV3Staker: [
      factory,
      nftManager,
      poolInitCodeHash,
    ].filter(Boolean) as string[],
    QuoterV2: [
      factory,
      weth,
      poolInitCodeHash,
    ].filter(Boolean) as string[],
    SwapRouter02: [
      factory,
      weth,
      nftManager,
      poolInitCodeHash,
    ].filter(Boolean) as string[],
    NonfungibleTokenPositionDescriptor: [
      weth,
      descriptorLib,
    ].filter(Boolean) as string[],
    V3Migrator: [
      factory,
      weth,
      nftManager,
      poolInitCodeHash,
    ].filter(Boolean) as string[],
    UniversalRouter: [
      permit2,
      weth,
      factory,
      nftManager,
      poolInitCodeHash,
      '0000000000000000000000000000000000000000000000000000000000000000', // pairInitCodeHash (zero)
    ].filter(Boolean) as string[],
  }
}

// Mask values in bytecode
function maskValues(bytecode: string, values: string[]): string {
  let masked = bytecode.toLowerCase()
  for (const value of values) {
    if (!value) continue
    const valueLower = value.toLowerCase()
    masked = masked.split(valueLower).join('x'.repeat(valueLower.length))
  }
  return masked
}

// Replace Uniswap-specific addresses with zeros
function normalizeUniswapBytecode(bytecode: string, contractName: string): string {
  const addressesToZero = UNISWAP_ADDRESSES_TO_ZERO[contractName]
  if (!addressesToZero) return bytecode

  let normalized = bytecode.toLowerCase()
  const zeroAddr = '0'.repeat(40)
  for (const addr of addressesToZero) {
    normalized = normalized.split(addr.toLowerCase()).join(zeroAddr)
  }
  return normalized
}

// Strip CBOR metadata from bytecode
function stripMetadata(bytecode: string): string {
  const bytes = bytecode.toLowerCase()
  if (bytes.length < 4) return bytes

  const metadataLengthHex = bytes.slice(-4)
  const metadataLength = parseInt(metadataLengthHex, 16)

  if (metadataLength > 0 && metadataLength < 100) {
    const strippedLength = bytes.length - (metadataLength * 2) - 4
    if (strippedLength > 0) {
      return bytes.slice(0, strippedLength)
    }
  }
  return bytes
}

interface BytecodeDiff {
  position: number
  kumbaya: string
  uniswap: string
}

function compareBytecode(kumbayaCode: string, uniswapCode: string): {
  identical: boolean
  sizeDiff: number
  differences: BytecodeDiff[]
} {
  const kBytes = kumbayaCode.slice(2)
  const uBytes = uniswapCode.slice(2)

  const differences: BytecodeDiff[] = []
  const maxLen = Math.max(kBytes.length, uBytes.length)

  for (let i = 0; i < maxLen; i += 2) {
    const kByte = kBytes.slice(i, i + 2) || '--'
    const uByte = uBytes.slice(i, i + 2) || '--'
    if (kByte.includes('x') || uByte.includes('x')) continue
    if (kByte !== uByte) {
      differences.push({ position: i / 2, kumbaya: kByte, uniswap: uByte })
    }
  }

  return {
    identical: differences.length === 0,
    sizeDiff: (kBytes.length - uBytes.length) / 2,
    differences,
  }
}

async function main() {
  const network = (process.argv[2] || 'testnet') as 'testnet' | 'mainnet'

  if (!['testnet', 'mainnet'].includes(network)) {
    console.error('Usage: npx tsx scripts/compare-bytecode.ts [testnet|mainnet]')
    process.exit(1)
  }

  console.log(`Loading ${network} addresses...`)
  const { rpc, contracts, poolInitCodeHash } = loadAddresses(network)

  if (!rpc) {
    console.error(`No RPC endpoint configured for ${network}`)
    process.exit(1)
  }

  const kumbayaChainId = network === 'testnet' ? 6343 : 4326
  const kumbayaProvider = new StaticJsonRpcProvider(rpc, { chainId: kumbayaChainId, name: `megaeth-${network}` })
  const ethereumProvider = new StaticJsonRpcProvider(RPC_ENDPOINTS.ethereum, { chainId: 1, name: 'mainnet' })
  const kumbayaImmutables = buildKumbayaImmutables(contracts, poolInitCodeHash)

  console.log('='.repeat(80))
  console.log(`BYTECODE COMPARISON: Kumbaya (MegaETH ${network}) vs Uniswap V3 (Ethereum)`)
  console.log('(With constructor args / immutables masked out)')
  console.log('='.repeat(80))
  console.log(`\nKumbaya POOL_INIT_CODE_HASH: 0x${poolInitCodeHash}`)
  console.log(`Uniswap POOL_INIT_CODE_HASH: 0x${UNISWAP_POOL_INIT_CODE_HASH}\n`)

  // Compare each contract
  for (const [contractName, uniswapAddr] of Object.entries(UNISWAP_CONTRACTS)) {
    const kumbayaAddr = contracts[contractName]

    if (!kumbayaAddr || kumbayaAddr === 'TBA') {
      console.log(`\n${'─'.repeat(80)}`)
      console.log(`[CONTRACT] ${contractName}`)
      console.log(`   [SKIP] Not deployed on ${network}`)
      continue
    }

    console.log(`\n${'─'.repeat(80)}`)
    console.log(`[CONTRACT] ${contractName}`)
    console.log(`   Kumbaya: ${kumbayaAddr}`)
    console.log(`   Uniswap: ${uniswapAddr}`)
    console.log('─'.repeat(80))

    try {
      const [kumbayaCode, uniswapCode] = await Promise.all([
        kumbayaProvider.getCode(kumbayaAddr),
        ethereumProvider.getCode(uniswapAddr),
      ])

      if (kumbayaCode === '0x') {
        console.log('   [WARN] Kumbaya contract has no code')
        continue
      }
      if (uniswapCode === '0x') {
        console.log('   [WARN] Uniswap contract has no code')
        continue
      }

      const kumbayaSize = (kumbayaCode.length - 2) / 2
      const uniswapSize = (uniswapCode.length - 2) / 2
      console.log(`   Kumbaya size: ${kumbayaSize.toLocaleString()} bytes`)
      console.log(`   Uniswap size: ${uniswapSize.toLocaleString()} bytes`)

      // Masked comparison (strip metadata first, then mask immutables)
      const kImmutables = kumbayaImmutables[contractName] || []
      const uImmutables = UNISWAP_IMMUTABLES[contractName] || []
      const normalizedUniswap = normalizeUniswapBytecode(uniswapCode, contractName)

      // Strip CBOR metadata before comparison (removes compiler version differences)
      const strippedKumbaya = '0x' + stripMetadata(kumbayaCode)
      const strippedUniswap = '0x' + stripMetadata(normalizedUniswap)
      const maskedKumbaya = maskValues(strippedKumbaya, kImmutables)
      const maskedUniswap = maskValues(strippedUniswap, uImmutables)
      const comparison = compareBytecode(maskedKumbaya, maskedUniswap)

      console.log('\n   [COMPARISON] (metadata stripped, immutables masked):')
      if (comparison.identical) {
        console.log('      [PASS] IDENTICAL - Logic bytecode matches')
      } else {
        console.log(`      [FAIL] ${comparison.differences.length} byte(s) differ`)

        // Always show the differences
        const diffToShow = comparison.differences.slice(0, 5)
        console.log('\n      First differences (position: kumbaya -> uniswap):')
        for (const diff of diffToShow) {
          console.log(`        ${diff.position.toString().padStart(6)}: 0x${diff.kumbaya} -> 0x${diff.uniswap}`)
        }
        if (comparison.differences.length > 5) {
          console.log(`        ... and ${comparison.differences.length - 5} more`)
        }

        // Show expected difference note if applicable
        const expectedReason = CONTRACTS_WITH_EXPECTED_DIFFERENCES[contractName]
        if (expectedReason) {
          console.log(`\n      [NOTE] Expected difference: ${expectedReason}`)
        }
      }
    } catch (error) {
      console.log(`   [ERROR] ${(error as Error).message}`)
    }
  }

  // Verify POOL_INIT_CODE_HASH
  console.log('\n' + '='.repeat(80))
  console.log('POOL_INIT_CODE_HASH VERIFICATION')
  console.log('='.repeat(80))

  const contractsWithHash = ['NonfungiblePositionManager', 'UniswapV3Staker', 'QuoterV2', 'SwapRouter02', 'UniversalRouter']

  for (const contractName of contractsWithHash) {
    const kumbayaAddr = contracts[contractName]
    if (!kumbayaAddr || kumbayaAddr === 'TBA') continue

    try {
      const code = await kumbayaProvider.getCode(kumbayaAddr)
      const bytecode = code.toLowerCase().slice(2)

      const kumbayaHashPos = bytecode.indexOf(poolInitCodeHash)
      const uniswapHashPos = bytecode.indexOf(UNISWAP_POOL_INIT_CODE_HASH)

      if (kumbayaHashPos !== -1) {
        console.log(`   [PASS] ${contractName}: Kumbaya hash found at byte ${kumbayaHashPos / 2}`)
      } else if (uniswapHashPos !== -1) {
        console.log(`   [FAIL] ${contractName}: WRONG! Uniswap hash found instead`)
      } else {
        console.log(`   [WARN] ${contractName}: Neither hash found`)
      }
    } catch (error) {
      console.log(`   [ERROR] ${contractName}: ${(error as Error).message}`)
    }
  }

  console.log('\n' + '='.repeat(80))
  console.log('Comparison complete')
  console.log('='.repeat(80))
}

main().catch(console.error)
