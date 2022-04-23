// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract APIConsumer is ChainlinkClient {

    function requestFloorPrice() public returns (bytes32 requestId) {}

    function fulfill(bytes32 _requestId, uint256 _floorPrice) public recordChainlinkFulfillment(_requestId) {}

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}

