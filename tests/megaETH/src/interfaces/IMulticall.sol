// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title UniswapInterfaceMulticall Interface
/// @notice A fork of Multicall2 specifically tailored for the Uniswap Interface
interface IMulticall {
    struct Call {
        address target;
        uint256 gasLimit;
        bytes callData;
    }

    struct Result {
        bool success;
        uint256 gasUsed;
        bytes returnData;
    }

    /// @notice Returns the current block timestamp
    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    /// @notice Returns the ETH balance of an address
    function getEthBalance(address addr) external view returns (uint256 balance);

    /// @notice Executes multiple calls in a single transaction
    /// @param calls Array of Call structs containing target, gasLimit, and callData
    /// @return blockNumber The block number when the calls were executed
    /// @return returnData Array of Result structs containing success, gasUsed, and returnData
    function multicall(Call[] calldata calls) external returns (uint256 blockNumber, Result[] memory returnData);
}
