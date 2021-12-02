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
    function viewCustomer(string memory _customerName)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(
            customers[_customerName].validatorBankAddress == address(0),
            "User doesn't exist on this database"
        );

        return (
            customers[_customerName].username,
            customers[_customerName].customerData,
            customers[_customerName].validatorBankAddress
        );
    }

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
        string memory _customerName,
        string memory _newCustomerData
    ) public {
        require(
            customers[_customerName].validatorBankAddress == address(0),
            "User doesn't exist. Please call addCustomer to create new user"
        );

        customers[_customerName].customerData = _newCustomerData;
    }
}