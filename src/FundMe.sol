// Get Funds From Users 
// Withdraw Funds
// Set A Minimum Funding Value In USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { PriceConverter } from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//  custom errors
error FundMe__NotOwner();

contract FundMe {
using PriceConverter for uint256; // this makes the PriceConverter accessible to all uint256(s) 

uint256 public constant MINIMUM_USD = 5e18; //using constant saves more gas
address[] private s_funders; // an array of address for funders
mapping(address => uint) private s_addressToAmountFunded; //key=>value pair of address to amount funded
// the payable keyword makes the function accept the native blockchain currency
// in this function, we want the gas price sent with the transaction to be more than 5 USD
    // we only want the owner of the contract to be able to withdraw from the contract. Hence, we'll use the constructor keyword
    address private immutable i_sender; //using immutable saves more gas
    AggregatorV3Interface private s_priceFeed;

    // this runs before a contract deploys
    constructor (address priceFeed) {
         i_sender = msg.sender;
         s_priceFeed = AggregatorV3Interface(priceFeed);
    } // it runs before the contract has been deployed

    function fund() public payable {
        // allow users to send $
        // have a minimum $ sent
        // how can we send ETH to this contract

        // the second parameter of the require function signifies the rzn for a failed transaction 
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough Eth"); //what is happening here is that
        // msg.value will be the first parameter of getConversioRate 
        // require(msg.value > minimumUSD, "didn't send enough ether"); gas prices are measured in wei
        s_funders.push(msg.sender); // get the sender of a transaction
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
    }

    function getVersion() public view returns (uint256){
      return s_priceFeed.version();
    }

    // this is for gas optimization
    function cheaperWithdraw() public onlyOwner {
    // here, we are going to try to optimize the code to not read from storage directly
    uint256 fundersLength = s_funders.length;
    for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
         address funder = s_funders[funderIndex];
         s_addressToAmountFunded[funder] = 0;
       }
     s_funders = new address[](0); 
    ( bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
    //  the (bool callSuccess) is like array desctructuring fron the rhs
    require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        // loop through the funders array and remove every sender and value that has sent us money stored in the addressToAmountFunded map
       for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
         address funder = s_funders[funderIndex];
         s_addressToAmountFunded[funder] = 0;
       } 
  
       // then reset the array to have a lenth of zero
       s_funders = new address[](0);

       // here, we'll withdraw the funds. There are three ways we can achieve this:
       //1. transfer
       //2. send
       //3. call    

    // 1. using the trf method
     payable(msg.sender).transfer(address(this).balance);
     // we type-casted the msg.sender to a payable address so it can recieve payments. 
     // the .transfer method takes the amount you want to send as a parameter
    //  N.B the transfer method reverts the whole operation if the gas fees exceeds 2300
    //  2. using the send method
     bool sendSuccess = payable(msg.sender).send(address(this).balance);
     //  N.B the send method returns a boolean(i.e false) if the gas fee of the computation exceeds 2300
     require(sendSuccess, "Send Failed"); // this way we have made the entire operation revert if it returns false
     ( bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
    //  the (bool callSuccess) is like array desctructuring fron the rhs
    require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        // require(msg.sender == i_sender, "must be owner, broski"); // this ensures that whoever calls the withdraw function is the owner
       if(msg.sender != i_sender) { revert FundMe__NotOwner(); }
        _;
    } 

// SPECIAL FUNCTIONS
   //if msg.data is empty in the calldata, default to receive(), i.e call the receive function
    receive() external payable { 
        fund();
    }
    //if msg.data is not empty in the calldata, default to fallback(), i.e call the fallback function
    fallback() external payable { 
        fund();
    }

    // view/pure functions (Getter functions)

// to check that s_addressToAmountFunded are actually being updated
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];   
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_sender;
    }
}