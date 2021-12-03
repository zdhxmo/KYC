// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract KYC_Contract {
    constructor() {
        admin = msg.sender;
    }

    address admin;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "You must have admin priviledges to run this"
        );
        _;
    }

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

    /* Mappings */

    // customer name to view customer details
    mapping(string => Customer) customers;

    // unique bank address to view bank details
    mapping(address => Bank) banks;

    // customer name to view KYC requests
    mapping(string => KYC_Request) KYC_requests;

    /* Events */

    event AddKYCRequest(string _customerName, string _customerData);
    event RemoveKYCRequest(string _customerName);
    event AddCustomer(string _customerName, string _customerData);
    event ModifyCustomer(string _customerName, string _newCustomerData);

    /*
     * Record a new KYC request on behalf of a customer
     * Bank is the sender of this request
     * @param {string}   _customerName The name of the customer for whom KYC is to be done
     * @param {string}  _customerData The hash of the customer data being requested
     * returns {bool}  returns true
     */
    function addKYCRequest(
        string memory _customerName,
        string memory _customerData
    ) public returns (bool) {
        // require that the request the bank is making isn't a duplicate
        require(
            !(KYC_requests[_customerName].bankAddress == msg.sender),
            "A KYC request already exists for this user from this bank"
        );

        // update KYC requests mapping
        KYC_requests[_customerName].username = _customerName;
        KYC_requests[_customerName].customerData = _customerData;
        KYC_requests[_customerName].bankAddress = msg.sender;

        // add KYC requests made by this bank
        banks[msg.sender].KYC_count++;

        emit AddKYCRequest(_customerName, _customerData);
        return true;
    }

    /*
     * Remove KYC request
     * @param {string} _customerName The name of the customer for whom KYC is to be removed
     * @param  {string} _customerData Hash of the customer's data
     * returns {bool}  returns true
     */
    function removeKYCRequest(string memory _customerName)
        public
        returns (bool)
    {
        // require that the username in fact exists as a KYC request
        require(
            !(KYC_requests[_customerName].bankAddress == msg.sender),
            "No KYC request exists for this customer. Please use addKYCRequest function"
        );

        // delete the customer's KYC request
        delete KYC_requests[_customerName];

        // reduce KYC requests made by this bank
        banks[msg.sender].KYC_count--;

        emit RemoveKYCRequest(_customerName);
        return true;
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
     * returns {bool}  returns true
     */
    function addCustomer(
        string memory _customerName,
        string memory _customerData
    ) public returns (bool) {
        require(
            customers[_customerName].validatorBankAddress == address(0),
            "User exists. Please call modifyCustomer to make any changes"
        );

        customers[_customerName].username = _customerName;
        customers[_customerName].customerData = _customerData;
        customers[_customerName].validatorBankAddress = msg.sender;

        emit AddCustomer(_customerName, _customerData);
        return true;
    }

    /*
     * Modify customer data
     * @param  {string} _customerName Name of the customer
     * @param  {string} _newCustomerData New hash of the updated docs
     */
    function modifyCustomer(
        string memory _customerName,
        string memory _newCustomerData
    ) public returns (bool) {
        require(
            customers[_customerName].validatorBankAddress == address(0),
            "User doesn't exist. Please call addCustomer to create new user"
        );

        customers[_customerName].customerData = _newCustomerData;

        emit ModifyCustomer(_customerName, _newCustomerData);
        return true;
    }
}
