// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.8;

// Imports
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();

// Interfaces

// Libraries

// Contracts

/**@title A contract for crowd funding
 * @author Patrick Collins
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables!
    uint256 public constant MINIMUM_USD = 50 * 1e18; // CAPPED NAME - const variable
    address[] private s_funders; //  s - storage variable, costs lots of gas
    mapping(address => uint256) private s_addressToAmountFunded; // s - storage variable, costs lots of gas
    address private immutable i_owner; // i - immutable variable, cheaper than storage variable
    AggregatorV3Interface public s_priceFeed; // s - storage variable, costs lots of gas

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Functions

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    //// constructor
    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    //// receive
    receive() external payable {
        fund();
    }

    //// fallback
    fallback() external payable {
        fund();
    }

    //// public
    /**
     * @notice This function funds this contract
     * @dev This function implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            // reset mapping
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset s_funders array
        s_funders = new address[](0);

        //// Withdraw the funds
        //// 1. transfer - automaticly reverts when the transfer fails
        //// msg.sender = address, payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        //// 2. send - only revert transaction when fails, if we add require statement
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // 3. call - low level code (advanced), recomended for sending Ether
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        // arrays can be in memory - safe gas
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // reset mapping
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset s_funders array
        s_funders = new address[](0);

        //// Withdraw the funds
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //// view / pure

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
