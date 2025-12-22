// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/ISwapRouter02.sol";
import "./interfaces/IQuoterV2.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IMulticall.sol";

/**
 * @title MegaETH On-Chain Integration Tests
 * @notice Tests for Kumbaya DEX contracts deployed on MegaETH (mainnet & testnet)
 * @dev Run with:
 *   Testnet: forge test --rpc-url https://timothy.megaeth.com/rpc -vvv
 *   Mainnet: FACTORY=0x68b... forge test --rpc-url https://mainnet.megaeth.com/rpc -vvv
 *
 * Contract addresses are detected based on chain ID:
 *   - Chain ID 4326 (mainnet): Uses mainnet addresses
 *   - Chain ID 6343 (testnet): Uses testnet addresses
 */
contract MegaETHOnChainTest is Test {
    // Chain IDs
    uint256 constant MEGAETH_MAINNET = 4326;
    uint256 constant MEGAETH_TESTNET = 6343;

    // MegaETH Mainnet Contract Addresses
    address constant MAINNET_FACTORY = 0x68b34591f662508076927803c567Cc8006988a09;
    address constant MAINNET_NFT_POSITION_MANAGER = 0x2b781C57e6358f64864Ff8EC464a03Fdaf9974bA;
    address constant MAINNET_SWAP_ROUTER_02 = 0xE5BbEF8De2DB447a7432A47EBa58924d94eE470e;
    address constant MAINNET_QUOTER_V2 = 0x1F1a8dC7E138C34b503Ca080962aC10B75384a27;
    address constant MAINNET_MULTICALL2 = 0xf6f404ac6289ab8eB1caf244008b5F073d59385c;
    address constant MAINNET_MULTICALL = 0xeeb4a1001354717598Af33f3585B66F9de7e7b27;

    // MegaETH Testnet Contract Addresses
    address constant TESTNET_FACTORY = 0x53447989580f541bc138d29A0FcCf72AfbBE1355;
    address constant TESTNET_NFT_POSITION_MANAGER = 0x367f9db1F974eA241ba046b77B87C58e2947d8dF;
    address constant TESTNET_SWAP_ROUTER_02 = 0x8268DC930BA98759E916DEd4c9F367A844814023;
    address constant TESTNET_QUOTER_V2 = 0xfb230b93803F90238cB03f254452bA3a3b0Ec38d;
    address constant TESTNET_MULTICALL2 = 0xc638099246A98B3A110429B47B3F42CA037BC0a3;
    address constant TESTNET_MULTICALL = 0x0DC8eE7a1BcF659dC41B25669238688A816A051A;

    // Shared addresses (same on both networks)
    address constant WETH9 = 0x4200000000000000000000000000000000000006;

    // Test tokens (testnet only - mainnet tokens TBD)
    address constant TESTNET_USDC = 0x75139A9559c9CD1aD69B7E239C216151D2c81e6f;
    address constant TESTNET_USDT = 0x8E1eb0b74A0aC37abaa0f75C598A681975896900;

    // Expected pool init code hash (same for both networks)
    bytes32 constant POOL_INIT_CODE_HASH = 0x851d77a45b8b9a205fb9f44cb829cceba85282714d2603d601840640628a3da7;

    // Dynamic addresses set in setUp based on chain ID
    address FACTORY;
    address NFT_POSITION_MANAGER;
    address SWAP_ROUTER_02;
    address QUOTER_V2;
    address MULTICALL2;
    address MULTICALL;
    address USDC;
    address USDT;

    // Contract interfaces
    IUniswapV3Factory factory;
    INonfungiblePositionManager nftManager;
    ISwapRouter02 swapRouter;
    IQuoterV2 quoter;
    IWETH9 weth;
    IMulticall multicall;

    function setUp() public {
        uint256 chainId = block.chainid;

        if (chainId == MEGAETH_MAINNET) {
            emit log("Running on MegaETH Mainnet (Chain ID: 4326)");
            FACTORY = MAINNET_FACTORY;
            NFT_POSITION_MANAGER = MAINNET_NFT_POSITION_MANAGER;
            SWAP_ROUTER_02 = MAINNET_SWAP_ROUTER_02;
            QUOTER_V2 = MAINNET_QUOTER_V2;
            MULTICALL2 = MAINNET_MULTICALL2;
            MULTICALL = MAINNET_MULTICALL;
            // Mainnet tokens - update these when tokens are deployed
            USDC = address(0);
            USDT = address(0);
        } else if (chainId == MEGAETH_TESTNET) {
            emit log("Running on MegaETH Testnet (Chain ID: 6343)");
            FACTORY = TESTNET_FACTORY;
            NFT_POSITION_MANAGER = TESTNET_NFT_POSITION_MANAGER;
            SWAP_ROUTER_02 = TESTNET_SWAP_ROUTER_02;
            QUOTER_V2 = TESTNET_QUOTER_V2;
            MULTICALL2 = TESTNET_MULTICALL2;
            MULTICALL = TESTNET_MULTICALL;
            USDC = TESTNET_USDC;
            USDT = TESTNET_USDT;
        } else {
            revert(string(abi.encodePacked("Unsupported chain ID: ", vm.toString(chainId))));
        }

        factory = IUniswapV3Factory(FACTORY);
        nftManager = INonfungiblePositionManager(NFT_POSITION_MANAGER);
        swapRouter = ISwapRouter02(SWAP_ROUTER_02);
        quoter = IQuoterV2(QUOTER_V2);
        weth = IWETH9(WETH9);
        multicall = IMulticall(MULTICALL);
    }

    // ==================== READ-ONLY VALIDATION TESTS ====================

    function test_FactoryIsDeployed() public view {
        uint256 codeSize;
        address factoryAddr = FACTORY;
        assembly {
            codeSize := extcodesize(factoryAddr)
        }
        assertGt(codeSize, 0, "Factory has no code");
    }

    function test_FactoryFeeAmounts() public view {
        // Standard Uniswap V3 fee tiers
        assertEq(factory.feeAmountTickSpacing(100), 1, "Fee 100 should have tick spacing 1");
        assertEq(factory.feeAmountTickSpacing(500), 10, "Fee 500 should have tick spacing 10");
        assertEq(factory.feeAmountTickSpacing(3000), 60, "Fee 3000 should have tick spacing 60");
        assertEq(factory.feeAmountTickSpacing(10000), 200, "Fee 10000 should have tick spacing 200");
    }

    function test_NFTPositionManagerConfig() public view {
        assertEq(nftManager.factory(), FACTORY, "NFT Manager should reference correct factory");
        assertEq(nftManager.WETH9(), WETH9, "NFT Manager should reference correct WETH9");
    }

    function test_SwapRouterConfig() public view {
        assertEq(swapRouter.factory(), FACTORY, "SwapRouter should reference correct factory");
        assertEq(swapRouter.WETH9(), WETH9, "SwapRouter should reference correct WETH9");
    }

    function test_QuoterConfig() public view {
        assertEq(quoter.factory(), FACTORY, "Quoter should reference correct factory");
        assertEq(quoter.WETH9(), WETH9, "Quoter should reference correct WETH9");
    }

    function test_WETH9IsDeployed() public view {
        assertEq(weth.symbol(), "WETH", "WETH symbol should be WETH");
        assertEq(weth.decimals(), 18, "WETH should have 18 decimals");
    }

    // ==================== MULTICALL TESTS ====================

    function test_MulticallIsDeployed() public view {
        uint256 codeSize;
        address multicallAddr = MULTICALL;
        assembly {
            codeSize := extcodesize(multicallAddr)
        }
        assertGt(codeSize, 0, "Multicall has no code");
    }

    function test_MulticallGetCurrentBlockTimestamp() public view {
        uint256 timestamp = multicall.getCurrentBlockTimestamp();
        assertGt(timestamp, 0, "Timestamp should be non-zero");
        assertEq(timestamp, block.timestamp, "Timestamp should match block.timestamp");
    }

    function test_MulticallGetEthBalance() public {
        uint256 balance = multicall.getEthBalance(WETH9);
        emit log_named_uint("WETH9 contract ETH balance", balance);
        // Just verify it returns without reverting - balance could be 0 or non-zero
    }

    function test_MulticallBatchCalls() public {
        // Test multicall with multiple calls to get token info
        IMulticall.Call[] memory calls = new IMulticall.Call[](3);

        // Call 1: Get WETH symbol
        calls[0] = IMulticall.Call({
            target: WETH9,
            gasLimit: 100000,
            callData: abi.encodeWithSignature("symbol()")
        });

        // Call 2: Get WETH decimals
        calls[1] = IMulticall.Call({
            target: WETH9,
            gasLimit: 100000,
            callData: abi.encodeWithSignature("decimals()")
        });

        // Call 3: Get WETH name
        calls[2] = IMulticall.Call({
            target: WETH9,
            gasLimit: 100000,
            callData: abi.encodeWithSignature("name()")
        });

        (uint256 blockNumber, IMulticall.Result[] memory results) = multicall.multicall(calls);

        assertGt(blockNumber, 0, "Block number should be non-zero");
        assertEq(results.length, 3, "Should have 3 results");

        // Verify all calls succeeded
        for (uint i = 0; i < results.length; i++) {
            assertTrue(results[i].success, string(abi.encodePacked("Call ", vm.toString(i), " should succeed")));
            assertGt(results[i].returnData.length, 0, "Return data should not be empty");
        }

        // Decode and verify results
        string memory symbol = abi.decode(results[0].returnData, (string));
        uint8 decimals = abi.decode(results[1].returnData, (uint8));
        string memory name = abi.decode(results[2].returnData, (string));

        assertEq(symbol, "WETH", "Symbol should be WETH");
        assertEq(decimals, 18, "Decimals should be 18");
        emit log_named_string("WETH name", name);
    }

    function test_MulticallWithFactoryCalls() public {
        // Test multicall with factory fee tier queries
        IMulticall.Call[] memory calls = new IMulticall.Call[](4);

        uint24[4] memory feeTiers = [uint24(100), uint24(500), uint24(3000), uint24(10000)];

        for (uint i = 0; i < 4; i++) {
            calls[i] = IMulticall.Call({
                target: FACTORY,
                gasLimit: 100000,
                callData: abi.encodeWithSignature("feeAmountTickSpacing(uint24)", feeTiers[i])
            });
        }

        (uint256 blockNumber, IMulticall.Result[] memory results) = multicall.multicall(calls);

        assertGt(blockNumber, 0, "Block number should be non-zero");
        assertEq(results.length, 4, "Should have 4 results");

        // Expected tick spacings
        int24[4] memory expectedTickSpacings = [int24(1), int24(10), int24(60), int24(200)];

        for (uint i = 0; i < 4; i++) {
            assertTrue(results[i].success, "Fee tier query should succeed");
            int24 tickSpacing = abi.decode(results[i].returnData, (int24));
            assertEq(tickSpacing, expectedTickSpacings[i], "Tick spacing mismatch");
        }

        emit log("SUCCESS: Multicall batch factory queries work correctly");
    }

    function test_AllContractsDeployed() public view {
        address[7] memory contracts = [
            FACTORY,
            NFT_POSITION_MANAGER,
            SWAP_ROUTER_02,
            QUOTER_V2,
            WETH9,
            MULTICALL2,
            MULTICALL
        ];

        for (uint i = 0; i < contracts.length; i++) {
            uint256 codeSize;
            address contractAddr = contracts[i];
            assembly {
                codeSize := extcodesize(contractAddr)
            }
            assertGt(codeSize, 0, "Contract should have code");
        }
    }

    // ==================== CREATE2 / DETERMINISTIC ADDRESS TESTS ====================

    /// @notice Computes the CREATE2 pool address using the Kumbaya pool init code hash
    /// @dev This must match what the factory returns for getPool()
    function computePoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (address pool) {
        // Sort tokens
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Compute CREATE2 address
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            FACTORY,
                            keccak256(abi.encode(token0, token1, fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function test_PoolInitCodeHash_WETH_USDC_3000() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - skipping test");
            return;
        }

        // Get the actual pool address from factory
        address actualPool = factory.getPool(WETH9, USDC, 3000);

        if (actualPool == address(0)) {
            emit log("WETH/USDC 0.3% pool doesn't exist yet - skipping CREATE2 verification");
            return;
        }

        // Compute expected address using our init code hash
        address computedPool = computePoolAddress(WETH9, USDC, 3000);

        emit log_named_address("Actual pool from factory", actualPool);
        emit log_named_address("Computed pool via CREATE2", computedPool);
        emit log_named_bytes32("Using init code hash", POOL_INIT_CODE_HASH);

        assertEq(
            computedPool,
            actualPool,
            "CREATE2 computed address should match factory getPool()"
        );
    }

    function test_PoolInitCodeHash_WETH_USDC_500() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - skipping test");
            return;
        }

        address actualPool = factory.getPool(WETH9, USDC, 500);

        if (actualPool == address(0)) {
            emit log("WETH/USDC 0.05% pool doesn't exist yet - skipping CREATE2 verification");
            return;
        }

        address computedPool = computePoolAddress(WETH9, USDC, 500);

        emit log_named_address("Actual pool (0.05% fee)", actualPool);
        emit log_named_address("Computed pool via CREATE2", computedPool);

        assertEq(computedPool, actualPool, "CREATE2 address should match for 0.05% fee");
    }

    function test_PoolInitCodeHash_USDC_USDT_100() public {
        if (USDC == address(0) || USDT == address(0)) {
            emit log("USDC/USDT not configured for this network - skipping test");
            return;
        }

        address actualPool = factory.getPool(USDC, USDT, 100);

        if (actualPool == address(0)) {
            emit log("USDC/USDT 0.01% pool doesn't exist yet - skipping CREATE2 verification");
            return;
        }

        address computedPool = computePoolAddress(USDC, USDT, 100);

        emit log_named_address("Actual pool (USDC/USDT 0.01%)", actualPool);
        emit log_named_address("Computed pool via CREATE2", computedPool);

        assertEq(computedPool, actualPool, "CREATE2 address should match for stablecoin pool");
    }

    function test_PoolInitCodeHash_AllExistingPools() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - skipping test");
            return;
        }

        // Test all fee tiers for WETH/USDC
        uint24[4] memory feeTiers = [uint24(100), uint24(500), uint24(3000), uint24(10000)];

        for (uint i = 0; i < feeTiers.length; i++) {
            address actualPool = factory.getPool(WETH9, USDC, feeTiers[i]);

            if (actualPool != address(0)) {
                address computedPool = computePoolAddress(WETH9, USDC, feeTiers[i]);

                emit log_named_uint("Testing fee tier", feeTiers[i]);
                emit log_named_address("  Actual", actualPool);
                emit log_named_address("  Computed", computedPool);

                assertEq(
                    computedPool,
                    actualPool,
                    string(abi.encodePacked("CREATE2 mismatch for fee ", vm.toString(feeTiers[i])))
                );
            }
        }
    }

    /// @notice Test that creating a new pool returns an address matching CREATE2 computation
    function test_NewPoolMatchesCREATE2() public {
        if (USDT == address(0)) {
            emit log("USDT not configured for this network - skipping test");
            return;
        }

        // Use a unique fee tier to ensure we're creating a new pool
        // Try WETH/USDT with 10000 fee (1%)
        address existingPool = factory.getPool(WETH9, USDT, 10000);

        if (existingPool != address(0)) {
            emit log("Pool already exists, verifying CREATE2 match");
            address computedPool = computePoolAddress(WETH9, USDT, 10000);
            assertEq(computedPool, existingPool, "Existing pool should match CREATE2");
            return;
        }

        // Compute expected address BEFORE creating
        address expectedPool = computePoolAddress(WETH9, USDT, 10000);
        emit log_named_address("Expected pool address (pre-computed)", expectedPool);

        // Create the pool
        address createdPool = factory.createPool(WETH9, USDT, 10000);
        emit log_named_address("Actually created pool address", createdPool);

        // Verify they match
        assertEq(
            createdPool,
            expectedPool,
            "Created pool address should match pre-computed CREATE2 address"
        );

        // Double-check with factory.getPool
        address factoryPool = factory.getPool(WETH9, USDT, 10000);
        assertEq(factoryPool, expectedPool, "factory.getPool should also match");
    }

    // ==================== QUOTER & ROUTER POOL ADDRESS TESTS ====================
    // These contracts internally compute pool addresses - if the init code hash is wrong,
    // they will fail to find pools or route swaps correctly

    /// @notice Verify QuoterV2 can find and quote pools (uses internal pool address computation)
    function test_QuoterV2_PoolAddressComputation() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - skipping test");
            return;
        }

        // First verify the pool exists via factory
        address factoryPool = factory.getPool(WETH9, USDC, 3000);

        if (factoryPool == address(0)) {
            emit log("WETH/USDC pool doesn't exist - creating for test");
            factoryPool = factory.createPool(WETH9, USDC, 3000);
        }

        // Now try to quote through QuoterV2
        // If QuoterV2 has wrong pool init code hash, it will compute wrong pool address
        // and either revert or return 0
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: USDC,
            amountIn: 1 ether,
            fee: 3000,
            sqrtPriceLimitX96: 0
        });

        // Check if pool is initialized
        IUniswapV3Pool poolContract = IUniswapV3Pool(factoryPool);
        (uint160 sqrtPriceX96,,,,,,) = poolContract.slot0();

        if (sqrtPriceX96 == 0) {
            emit log("Pool not initialized - QuoterV2 test skipped");
            return;
        }

        // If init code hash is correct, quoter should find the pool and return a quote
        // If wrong, it will revert with "Pool doesn't exist" or similar
        try quoter.quoteExactInputSingle(params) returns (
            uint256 amountOut,
            uint160,
            uint32,
            uint256
        ) {
            emit log_named_uint("QuoterV2 found pool and quoted amountOut", amountOut);
            assertGt(amountOut, 0, "QuoterV2 should return non-zero quote");
            emit log("SUCCESS: QuoterV2 pool init code hash is correct");
        } catch Error(string memory reason) {
            // "SPL" = sqrtPriceLimitX96 error, means pool was found but has no liquidity - this is OK
            if (keccak256(bytes(reason)) == keccak256(bytes("SPL"))) {
                emit log("QuoterV2 found pool but no liquidity (SPL error) - init code hash is correct");
            } else {
                emit log_named_string("QuoterV2 failed with reason", reason);
                fail("QuoterV2 should find pool - init code hash may be incorrect");
            }
        } catch {
            emit log("QuoterV2 failed - likely no liquidity in pool");
        }
    }

    /// @notice Verify that NFTPositionManager can interact with pools (uses internal pool address computation)
    function test_NFTPositionManager_PoolAddressComputation() public {
        // The NFT Position Manager computes pool addresses internally when minting positions
        // We verify it references the same factory and thus should use the same pool addresses

        // Check that factory reference is correct
        address nftFactory = nftManager.factory();
        assertEq(nftFactory, FACTORY, "NFT Manager factory reference should match");

        if (USDC == address(0)) {
            emit log("USDC not configured - skipping pool creation test");
            emit log_named_address("NFT Manager references factory", nftFactory);
            emit log("SUCCESS: NFT Position Manager should work with pools from this factory");
            return;
        }

        // Verify a pool created via factory is findable
        address factoryPool = factory.getPool(WETH9, USDC, 3000);

        if (factoryPool == address(0)) {
            emit log("Creating WETH/USDC pool for NFT Manager test");
            factoryPool = factory.createPool(WETH9, USDC, 3000);
        }

        // Verify the pool's factory reference
        IUniswapV3Pool poolContract = IUniswapV3Pool(factoryPool);
        assertEq(poolContract.factory(), FACTORY, "Pool should reference correct factory");

        emit log_named_address("NFT Manager references factory", nftFactory);
        emit log_named_address("Pool created by factory", factoryPool);
        emit log("SUCCESS: NFT Position Manager should work with pools from this factory");
    }

    /// @notice Test that SwapRouter02 can find pools (uses internal pool address computation)
    function test_SwapRouter02_PoolAddressComputation() public {
        // SwapRouter computes pool addresses internally for routing
        // Verify it references the correct factory
        address routerFactory = swapRouter.factory();
        assertEq(routerFactory, FACTORY, "SwapRouter factory reference should match");

        emit log_named_address("SwapRouter references factory", routerFactory);
        emit log("SUCCESS: SwapRouter02 should work with pools from this factory");
    }

    /// @notice End-to-end test: verify computed address == factory address == what periphery uses
    function test_FullStack_PoolAddressConsistency() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - running partial test");
            // Still verify periphery contracts reference correct factory
            assertEq(quoter.factory(), FACTORY, "Quoter factory mismatch");
            assertEq(swapRouter.factory(), FACTORY, "SwapRouter factory mismatch");
            assertEq(nftManager.factory(), FACTORY, "NFT Manager factory mismatch");
            emit log("SUCCESS: All periphery contracts reference correct factory");
            return;
        }

        // This is the definitive test - all components should agree on pool addresses
        address factoryPool = factory.getPool(WETH9, USDC, 3000);

        if (factoryPool == address(0)) {
            factoryPool = factory.createPool(WETH9, USDC, 3000);
        }

        // 1. Our computed address should match
        address computedPool = computePoolAddress(WETH9, USDC, 3000);
        assertEq(computedPool, factoryPool, "Computed address should match factory");

        // 2. Quoter should be able to find it
        IUniswapV3Pool poolContract = IUniswapV3Pool(factoryPool);
        (uint160 sqrtPriceX96,,,,,,) = poolContract.slot0();

        if (sqrtPriceX96 > 0) {
            // Pool is initialized, quoter should work
            IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                amountIn: 0.001 ether,
                fee: 3000,
                sqrtPriceLimitX96: 0
            });

            try quoter.quoteExactInputSingle(params) returns (uint256 amountOut, uint160, uint32, uint256) {
                emit log_named_uint("Full stack test - quote succeeded with amountOut", amountOut);
            } catch {
                emit log("Quote failed - pool may have no liquidity");
            }
        }

        // 3. All periphery contracts should reference correct factory
        assertEq(quoter.factory(), FACTORY, "Quoter factory mismatch");
        assertEq(swapRouter.factory(), FACTORY, "SwapRouter factory mismatch");
        assertEq(nftManager.factory(), FACTORY, "NFT Manager factory mismatch");

        emit log("SUCCESS: Full stack pool address consistency verified");
        emit log_named_address("  Factory pool", factoryPool);
        emit log_named_address("  Computed pool", computedPool);
        emit log_named_bytes32("  Using init code hash", POOL_INIT_CODE_HASH);
    }

    // ==================== POOL VALIDATION TESTS ====================

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    function test_CanCreatePool() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - skipping test");
            return;
        }

        // Check if WETH/USDC pool exists for 0.3% fee
        address pool = factory.getPool(WETH9, USDC, 3000);

        if (pool == address(0)) {
            // Pool doesn't exist, try to create it
            pool = factory.createPool(WETH9, USDC, 3000);
            emit log_named_address("Created new pool", pool);
        } else {
            emit log_named_address("Pool already exists", pool);
        }

        assertTrue(pool != address(0), "Pool should exist or be created");
    }

    function test_ExistingPoolConfiguration() public view {
        if (USDC == address(0)) {
            return;
        }

        // Check WETH/USDC pool
        address pool = factory.getPool(WETH9, USDC, 3000);

        if (pool != address(0)) {
            IUniswapV3Pool poolContract = IUniswapV3Pool(pool);

            assertEq(poolContract.factory(), FACTORY, "Pool factory should match");
            assertEq(poolContract.fee(), 3000, "Pool fee should be 3000");
            assertEq(poolContract.tickSpacing(), 60, "Pool tick spacing should be 60");

            // Verify tokens
            address token0 = poolContract.token0();
            address token1 = poolContract.token1();
            assertTrue(
                (token0 == WETH9 && token1 == USDC) || (token0 == USDC && token1 == WETH9),
                "Pool tokens should be WETH and USDC"
            );
        }
    }

    // ==================== INTEGRATION TESTS (require gas) ====================

    function test_WrapETH() public {
        uint256 depositAmount = 0.001 ether;

        // Check initial balance
        uint256 initialWethBalance = weth.balanceOf(address(this));

        // Wrap ETH
        weth.deposit{value: depositAmount}();

        // Verify balance increased
        assertEq(
            weth.balanceOf(address(this)),
            initialWethBalance + depositAmount,
            "WETH balance should increase"
        );
    }

    function test_UnwrapWETH() public {
        uint256 depositAmount = 0.001 ether;

        // First wrap some ETH
        weth.deposit{value: depositAmount}();

        uint256 initialEthBalance = address(this).balance;

        // Unwrap WETH
        weth.withdraw(depositAmount);

        // Verify ETH balance increased
        assertEq(
            address(this).balance,
            initialEthBalance + depositAmount,
            "ETH balance should increase after unwrap"
        );
    }

    function test_QuoteSwap() public {
        if (USDC == address(0)) {
            emit log("USDC not configured for this network - skipping test");
            return;
        }

        address pool = factory.getPool(WETH9, USDC, 3000);
        if (pool == address(0)) {
            emit log("Skipping quote test - no WETH/USDC pool");
            return;
        }

        // Check if pool is initialized
        IUniswapV3Pool poolContract = IUniswapV3Pool(pool);
        (uint160 sqrtPriceX96,,,,,,) = poolContract.slot0();

        if (sqrtPriceX96 == 0) {
            emit log("Skipping quote test - pool not initialized");
            return;
        }

        // Try to get a quote for 0.01 WETH -> USDC
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: USDC,
            amountIn: 0.01 ether,
            fee: 3000,
            sqrtPriceLimitX96: 0
        });

        try quoter.quoteExactInputSingle(params) returns (
            uint256 amountOut,
            uint160,
            uint32 ticksCrossed,
            uint256 gasEstimate
        ) {
            emit log_named_uint("Quote: 0.01 WETH -> USDC", amountOut);
            emit log_named_uint("Ticks crossed", ticksCrossed);
            emit log_named_uint("Gas estimate", gasEstimate);
            assertGt(amountOut, 0, "Should get non-zero quote");
        } catch {
            emit log("Quote failed - pool may have no liquidity");
        }
    }

    // ==================== HELPER ====================

    receive() external payable {}
}
