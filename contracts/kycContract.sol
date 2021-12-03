pragma solidity ^0.8.9;

contract kycContract {
    struct Customer {
        string username;
        // hash that points to customer documents in secure storage
        string customerData;
        // status of KYC request. if conditions are met, set to true. else false
        bool kycRequest;
        // number of upvotes from other banks to customer data
        uint256 upVotes;
        // number of downvotes from other banks to customer data
        uint256 downVotes;
        // unique address of the validating bank
        address validatorBankAddress;
    }

    struct Bank {
        string name;
        // unique ethereum address of the bank
        address ethAddress;
        // total complaints against the bank by other banks in the network
        uint256 complaintsReported;
        //number of KYC requests initiated by bank
        uint256 KYC_count;
        // status. if false, bank cannot up/down vote any more customers
        bool isAllowedToVote;
        // registration number of the bank
        string regNumber;
    }

    struct KYC_Request {
        // map KYC request to customer data
        string username;
        // hash that points to customer documents in secure storage
        string customerData;
        // unique account address of the bank
        address bankAddress;
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
