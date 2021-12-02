pragma solidity ^0.8.9;

contract kycContract {
    struct Customer {
        string username;
        // hash of the documents submitted by the customer
        string customerData;
        // unique address of the validating bank
        address validatorBankAddress;
    }

    struct Bank {
        string name;
        // unique ethereum address of the bank
        address ethAddress;
        // registration number of the bank
        string regNumber;
    }

    mapping(string => Customer) customers;
    mapping(address => Bank) banks;

    // function to view customer
    function viewCustomer(string memory customerName)
        public
        returns (string memory)
    {}

    // function to add customers mapped to their documents
    function addCustomer(
        string memory _customerName,
        string memory _customerData
    ) public {
        require(
            customers[_customerName].validatorBankAddress == address(0),
            "User exists. Please call modifyCustomer to make any changes"
        );

        customers[_customerName].username = _customerName;
        customers[_customerName].customerData = _customerData;
        customers[_customerName].validatorBankAddress = msg.sender;
    }

    // function to edit customer details
    function modifyCustomer(
        string memory customerName,
        string memory newDataHash
    ) public returns (uint256) {}

}
