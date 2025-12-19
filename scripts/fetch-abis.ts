#!/usr/bin/env npx tsx
/**
 * Fetches/extracts ABIs for all contracts in addresses.json.
 *
 * Sources (in order of preference):
 * 1. Kumbaya build artifacts (../v3-core, ../v3-periphery, etc.)
 * 2. Block explorer API (for verified contracts)
 *
 * Usage:
 *   npx tsx scripts/fetch-abis.ts
 *   npx tsx scripts/fetch-abis.ts --dry-run  # Preview without writing files
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT_DIR = join(__dirname, '..');
const KUMBAYA_ROOT = join(ROOT_DIR, '..');

interface AddressesJson {
  chainId: number;
  chainName: string;
  rpc: string;
  blockExplorer: string;
  contracts: Record<string, string>;
  poolInitCodeHash: string;
}

const ARTIFACT_SOURCES: Record<string, { repo: string; path: string }> = {
  UniswapV3Factory: { repo: 'v3-core', path: 'artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json' },
  UniswapV3Pool: { repo: 'v3-core', path: 'artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json' },
  NonfungiblePositionManager: { repo: 'v3-periphery', path: 'artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json' },
  V3Migrator: { repo: 'v3-periphery', path: 'artifacts/contracts/V3Migrator.sol/V3Migrator.json' },
  TickLens: { repo: 'v3-periphery', path: 'artifacts/contracts/lens/TickLens.sol/TickLens.json' },
  Multicall2: { repo: 'v3-periphery', path: 'artifacts/contracts/lens/Multicall2.sol/Multicall2.json' },
  NonfungibleTokenPositionDescriptor: { repo: 'v3-periphery', path: 'artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json' },
  SwapRouter02: { repo: 'swap-router-contracts', path: 'artifacts/contracts/SwapRouter02.sol/SwapRouter02.json' },
  QuoterV2: { repo: 'swap-router-contracts', path: 'artifacts/contracts/lens/QuoterV2.sol/QuoterV2.json' },
  UniswapV3Staker: { repo: 'v3-staker', path: 'artifacts/contracts/UniswapV3Staker.sol/UniswapV3Staker.json' },
  UniversalRouter: { repo: 'universal-router', path: 'artifacts/contracts/UniversalRouter.sol/UniversalRouter.json' },
  ERC20: { repo: 'v3-periphery', path: 'node_modules/@openzeppelin/contracts/build/contracts/ERC20.json' },
};

const SKIP_CONTRACTS = new Set([
  'WETH9',
  'ProxyAdmin',
  'DescriptorProxy',
  'NonfungibleTokenDescriptorLibrary',
]);

const ADDITIONAL_ABIS = ['UniswapV3Pool', 'ERC20'];

function extractAbiFromArtifact(artifactPath: string): object | null {
  try {
    if (!existsSync(artifactPath)) {
      return null;
    }
    const artifact = JSON.parse(readFileSync(artifactPath, 'utf-8'));
    return artifact.abi || null;
  } catch {
    return null;
  }
}

async function fetchAbiFromExplorer(
  address: string,
  explorerUrl: string
): Promise<object | null> {
  const apiUrl = `${explorerUrl.replace(/\/$/, '')}/api/v2/smart-contracts/${address}`;

  try {
    const response = await fetch(apiUrl);
    if (!response.ok) return null;

    const data = await response.json();
    return data.abi || null;
  } catch {
    return null;
  }
}

async function fetchPermit2Abi(): Promise<object | null> {
  const PERMIT2_ADDRESS = '0x000000000022D473030F116dDEE9F6B43aC78BA3';
  const apiKey = process.env.ETHERSCAN_API_KEY || '';
  const apiUrl = `https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getabi&address=${PERMIT2_ADDRESS}${apiKey ? `&apikey=${apiKey}` : ''}`;

  try {
    const response = await fetch(apiUrl);
    if (!response.ok) return null;

    const data = await response.json();
    if (data.status === '1' && data.result) {
      return JSON.parse(data.result);
    }
    if (data.result && data.status !== '1') {
      console.log(`   Etherscan: ${data.result}`);
    }
    return null;
  } catch (error) {
    console.log(`   Etherscan error: ${error}`);
    return null;
  }
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');

  if (dryRun) {
    console.log('[DRY RUN] No files will be written\n');
  }

  const addressesPath = join(ROOT_DIR, 'addresses.json');
  const addresses: AddressesJson = JSON.parse(readFileSync(addressesPath, 'utf-8'));

  console.log(`Loading contracts from ${addresses.chainName} (Chain ID: ${addresses.chainId})`);
  console.log(`Explorer: ${addresses.blockExplorer}\n`);

  const abisDir = join(ROOT_DIR, 'abis');
  if (!existsSync(abisDir) && !dryRun) {
    mkdirSync(abisDir, { recursive: true });
  }

  const results: { name: string; status: string; source?: string }[] = [];

  const contractsToProcess = new Set([
    ...Object.keys(addresses.contracts),
    ...ADDITIONAL_ABIS,
  ]);

  for (const contractName of contractsToProcess) {
    const address = addresses.contracts[contractName];

    console.log(`\n${contractName}`);
    if (address) {
      console.log(`  Address: ${address}`);
    }

    if (SKIP_CONTRACTS.has(contractName)) {
      console.log(`  [SKIP] proxy/library`);
      results.push({ name: contractName, status: 'skipped' });
      continue;
    }

    let abi: object | null = null;
    let source = '';

    const artifactInfo = ARTIFACT_SOURCES[contractName];
    if (artifactInfo) {
      const artifactPath = join(KUMBAYA_ROOT, artifactInfo.repo, artifactInfo.path);
      abi = extractAbiFromArtifact(artifactPath);
      if (abi) {
        source = `${artifactInfo.repo} artifacts`;
      }
    }

    if (!abi && contractName === 'Permit2') {
      console.log(`   Fetching from Etherscan mainnet (canonical deployment)...`);
      abi = await fetchPermit2Abi();
      if (abi) {
        source = 'Etherscan mainnet (canonical)';
      }
      await new Promise(resolve => setTimeout(resolve, 300));
    }

    if (!abi && address) {
      console.log(`   Trying explorer...`);
      abi = await fetchAbiFromExplorer(address, addresses.blockExplorer);
      if (abi) {
        source = 'block explorer';
      }
      await new Promise(resolve => setTimeout(resolve, 300));
    }

    if (abi) {
      const abiPath = join(abisDir, `${contractName}.json`);

      if (dryRun) {
        console.log(`  [OK] Would write ABI from ${source}`);
      } else {
        writeFileSync(abiPath, JSON.stringify(abi, null, 2) + '\n');
        console.log(`  [OK] Saved from ${source}`);
      }
      results.push({ name: contractName, status: 'fetched', source });
    } else {
      console.log(`  [FAIL] Could not fetch ABI`);
      results.push({ name: contractName, status: 'failed' });
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('Summary\n');

  const fetched = results.filter(r => r.status === 'fetched');
  const skipped = results.filter(r => r.status === 'skipped');
  const failed = results.filter(r => r.status === 'failed');

  console.log(`Fetched: ${fetched.length}`);
  fetched.forEach(r => console.log(`  - ${r.name} (${r.source})`));

  if (skipped.length > 0) {
    console.log(`\nSkipped: ${skipped.length}`);
    skipped.forEach(r => console.log(`  - ${r.name}`));
  }

  if (failed.length > 0) {
    console.log(`\nFailed: ${failed.length}`);
    failed.forEach(r => console.log(`  - ${r.name}`));

    if (failed.some(r => r.name === 'Permit2')) {
      console.log('\nHint: For Permit2, set ETHERSCAN_API_KEY env var (free at etherscan.io)');
      console.log('  ETHERSCAN_API_KEY=your-key npx tsx scripts/fetch-abis.ts');
    }

    console.log('\nHint: For other contracts, run builds in the source repos:');
    console.log('  cd ../v3-core && yarn compile');
    console.log('  cd ../v3-periphery && yarn compile');
    console.log('  cd ../swap-router-contracts && yarn compile');
    console.log('  cd ../v3-staker && yarn compile');
    console.log('  cd ../universal-router && forge build');
  }

  if (!dryRun) {
    console.log(`\nABIs written to: ${abisDir}`);
  }
}

main().catch(console.error);
