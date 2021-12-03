// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract KYC_Contract {
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

    // count of total banks in the network
    uint256 totalBanks;


    struct KYC_Request {
        // map KYC request to customer data
        string username;
        // hash that points to customer documents in secure storage
        string customerData;
        // unique account address of the bank
        address bankAddress;
    }

    // customer name to view customer details
    mapping(string => Customer) customers;

    // unique bank address to view bank details
    mapping(address => Bank) banks;

    // customer document hash to view kyc requests
    mapping(string => KYC_Request) KYCrequests;

    /*
     * Record a new KYC request on behalf of a customer
     * Bank is the sender of this request
     * @param {string}   _customerName The name of the customer for whom KYC is to be done
     * @param {string}  _customerData The hash of the customer data being requested
     */
    function addKYCRequest(
        string memory _customerName,
        string memory _customerData
    ) public {
        // require that the request the bank is making isn't a duplicate
        require(
            !(KYCrequests[_customerName].bankAddress == msg.sender),
            "A KYC request already exists for this user from this bank"
        );

        // update KYC requests mapping
        KYCrequests[_customerName].username = _customerName;
        KYCrequests[_customerName].customerData = _customerData;
        KYCrequests[_customerName].bankAddress = msg.sender;

        // add KYC requests made by this bank
        banks[msg.sender].KYC_count++;
    }

    /*
     * View customer information
     * @param  {public}  _customerName Name of the customer
     * @return {Customer} The customer struct as an object
     */
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

    /*
     * Add a new customer
     * @param {string} _userName Name of the customer
     * @param {string} _customerData Hash of the customer docs
     */
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

    /*
     * Modify customer data
     * @param  {string} _customerName Name of the customer
     * @param  {string} _newCustomerData New hash of the updated docs
     */
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
