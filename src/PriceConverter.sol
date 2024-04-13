//  creating libraries

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
// get the value of one ETH to USD
    function getPrice(AggregatorV3Interface priceFeed) public view returns(uint256) {
            (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData(); //this will return a value in 8 dp but we need it in value of wei, which is 18 dp
        // so we need to add an additional 10 dp which is why we multiply by 1e10 
        return uint(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) public view returns(uint256) {
        // get the amount in 
       uint256 ethPrice = getPrice(priceFeed); 
       uint ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
       return ethAmountInUSD;
    }
    
}