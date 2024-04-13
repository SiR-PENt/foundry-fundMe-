//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // create dummy address of a user
    uint256 constant SEND_VALUE = 10e18;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
// note that on calling every test function, setUp runs first again
    function setUp() external {
        // inside of this, we'll deploy our new contract
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // cheat code to set the balance of an address to a new balance
    } //the first function that runs before any other ones

    function testMinimumDollarIsFive() view public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() view public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // there a 4 types of testing
    // 1. unit: Test a specific part of the code
    // 2. integration: tests how well the code works with other parts of the code
    // 3. Forked: Testing our code on a simulated real environment
    // 4. Staging: testing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() view public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // this is used to check if the next fails. if it does, the test is successful, if not , it isn't
        fundMe.fund(); // call fund without a value to send for the tx
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // this means that the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

// this test checks if the user that sends this tx is the actual funder
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // remember that this means the next tx is sent by USER
        fundMe.fund{value: SEND_VALUE}(); // deploy fund with SEND_VALUE
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    // since we may be funding the user many times, it's advisable to create a modifier for it

    modifier funded() {
        vm.prank(USER); //the next tx is sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

   function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); // ---------
        vm.expectRevert(); //      | this would revert because USER is not the owner
        fundMe.withdraw(); //<------ vm.prank skips the next vm, to the fundMe.withdraw() function
        // so here, we fund the USER's acct
        //  then we say
    }

    function testCheaperWithdrawWithASingleFunder() public funded {
        // testing methodology

        //1. Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // get the balance of the owner before withdraw is called
        uint256 startingFundMeBalance = address(fundMe).balance; // get the balance of the fundMe contract after it has been funded

        //2. Act
        vm.prank(fundMe.getOwner()); // the next tx should be called by the owner
        fundMe.cheaperWithdraw(); // withdraw to the owner's addr
        
        //3. Assert
        // now, after withdraw, we want to check the balance of the owner 
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        // check the balance of the contract address after withdraw
        uint256 endingFundMeBalance = address(fundMe).balance;
        // assert that the contract's balance is 0 after withdrawing
        assertEq(endingFundMeBalance, 0);
        // assert that the 
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
    
    function testWithdrawWithASingleFunder() public funded {
        // testing methodology

        //1. Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // get the balance of the owner before withdraw is called
        uint256 startingFundMeBalance = address(fundMe).balance; // get the balance of the fundMe contract after it has been funded

        //2. Act
        vm.prank(fundMe.getOwner()); // the next tx should be called by the owner
        fundMe.withdraw(); // withdraw to the owner's addr
        
        //3. Assert
        // now, after withdraw, we want to check the balance of the owner 
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        // check the balance of the contract address after withdraw
        uint256 endingFundMeBalance = address(fundMe).balance;
        // assert that the contract's balance is 0 after withdrawing
        assertEq(endingFundMeBalance, 0);
        // assert that the 
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
       // uint160 has the same amount of bytes as an address
        // if you want to use numbers to generate addresses, they have to be uint160
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
          hoax(address(i), SEND_VALUE); // hoax: Prank and deal at the same time
          fundMe.fund{value: SEND_VALUE}();
        }
           uint256 startingOwnerBalance = fundMe.getOwner().balance; // get the balance of the owner before withdraw is called
           uint256 startingFundMeBalance = address(fundMe).balance; // get the balance of the fundMe contract after it has been funded
           vm.txGasPrice(GAS_PRICE);
           vm.prank(fundMe.getOwner());
           fundMe.withdraw();

           assert(address(fundMe).balance == 0);
           assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
