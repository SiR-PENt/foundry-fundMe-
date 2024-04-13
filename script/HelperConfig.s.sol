// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";

// this contract helps us to deploy the fundMe contract based on the network of the address we receive

contract HelperConfig is Script {
    // if we are on a local chain, we deploy mocks
    // else, we get the existing address from the live network

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;
    // constants for the contructor in the mockaggregator
    uint8 public constant DEMICALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            //this is sepolia chainid
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();    
        }
    }

    // here we will get the address of the sepolia network
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //we used memory here cos it's a special kind of obj?
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    // this condition checks for if a contract has been previously deployed
    // N.B a contract defaults to address(0) if it doesn't exist
     if(activeNetworkConfig.priceFeed != address(0)) {
        return activeNetworkConfig;
     }
     // since this is a local ntwk, contracts dont exist for pricefeeds
     //  what we are gonna do is then:
     // 1. deploy the mock contract
     //2. get the address of the mock contract 

      vm.startBroadcast();
      MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DEMICALS, INITIAL_PRICE);
      vm.stopBroadcast();

      NetworkConfig memory anvilConfig = NetworkConfig({
        priceFeed: address(mockPriceFeed)
      });
      return anvilConfig;
    }
}
// creating a mock contract
