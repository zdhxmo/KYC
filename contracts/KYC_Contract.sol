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
        uint32 upVotes;
        // number of downvotes from other banks to customer data
        uint32 downVotes;
        // unique address of the validating bank
        address validatorBankAddress;
    }

    struct Bank {
        string name;
        // unique ethereum address of the bank
        address ethAddress;
        // total complaints against the bank by other banks in the network
        uint32 complaintsReported;
        //number of KYC requests initiated by bank
        uint32 KYC_count;
        // status. if false, bank cannot up/down vote any more customers
        bool isAllowedToVote;
        // registration number of the bank
        string regNumber;
    }

    // count of total banks in the network
    uint32 totalBanks;

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

    // keep track of up votes for the customer by all banks in the network
    mapping(string => mapping(address => uint8)) up_votes;

    // keep track of down votes for the customer by all banks in the network
    mapping(string => mapping(address => uint8)) down_votes;

    /* Events */

    event AddKYCRequest(
        string _customerName,
        string _customerData,
        address KYCRequestingBank
    );
    event RemoveKYCRequest(string _customerName, address KYCRemovingBank);

    event AddCustomer(
        string _customerName,
        string _customerData,
        address validatorBank
    );
    event ModifyCustomer(
        string _customerName,
        string _newCustomerData,
        address bankAddress
    );

    event UpVoteCustomer(string _customerName, address bankAddress);
    event RemoveUpVoteCustomer(string _customerName, address bankAddress);

    event DownVoteCustomer(string _customerName, address bankAddress);
    event RemoveDownVoteCustomer(string _customerName, address bankAddress);

    /**
     * Record a new KYC request on behalf of a customer
     * Bank is the sender of this request
     * @param _customerName The name of the customer for whom KYC is to be done
     * @param _customerData The hash of the customer data being requested
     * @return bool
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

        require(
            compareStringsbyBytes(
                customers[_customerName].customerData,
                _customerData
            ),
            "Please check hash. This record doesn't exist"
        );

        // update KYC requests mapping
        KYC_requests[_customerName].username = _customerName;
        KYC_requests[_customerName].customerData = _customerData;
        KYC_requests[_customerName].bankAddress = msg.sender;

        // add KYC requests made by this bank
        banks[msg.sender].KYC_count++;

        emit AddKYCRequest(_customerName, _customerData, msg.sender);
        return true;
    }

    /**
     * Remove KYC request
     * @param _customerName The name of the customer for whom KYC is to be removed
     * @return bool
     */
    function removeKYCRequest(string memory _customerName)
        public
        returns (bool)
    {
        // require that the username in fact exists as a KYC request
        require(
            (KYC_requests[_customerName].bankAddress == msg.sender),
            "No KYC request exists for this customer. Please use addKYCRequest function"
        );

        require(
            compareStringsbyBytes(
                customers[_customerName].username,
                _customerName
            ),
            "No request exists for this customer. Please use addKYCRequest function"
        );

        // delete the customer's KYC request
        delete KYC_requests[_customerName];

        // reduce KYC requests made by this bank
        banks[msg.sender].KYC_count--;

        emit RemoveKYCRequest(_customerName, msg.sender);
        return true;
    }

    /**
     * View customer information
     * @param _customerName Name of the customer
     * @return struct Customer - The customer struct as an object
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
            customers[_customerName].validatorBankAddress ==
                address(msg.sender),
            "User doesn't exist on this database. Use addCustomer to create user"
        );

        return (
            customers[_customerName].username,
            customers[_customerName].customerData,
            customers[_customerName].validatorBankAddress
        );
    }

    /**
     * Add a new customer
     * @param _customerName Name of the customer
     * @param _customerData Hash of the customer docs
     * @return bool
     */
    function addCustomer(
        string memory _customerName,
        string memory _customerData
    ) public returns (bool) {
        require(
            customers[_customerName].validatorBankAddress == address(0x0),
            "User exists. Please call modifyCustomer to make any changes"
        );

        customers[_customerName].username = _customerName;
        customers[_customerName].customerData = _customerData;
        customers[_customerName].validatorBankAddress = msg.sender;

        emit AddCustomer(_customerName, _customerData, msg.sender);
        return true;
    }

    /**
     * Modify customer data
     * @param _customerName Name of the customer
     * @param _newCustomerData New hash of the updated docs
     * @return bool
     */
    function modifyCustomer(
        string memory _customerName,
        string memory _newCustomerData
    ) public returns (bool) {
        require(
            customers[_customerName].validatorBankAddress ==
                address(msg.sender),
            "User doesn't exist. Please call addCustomer to create new user"
        );

        customers[_customerName].customerData = _newCustomerData;

        emit ModifyCustomer(_customerName, _newCustomerData, msg.sender);
        return true;
    }

    /**
     * Function to add a new up vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool
     */
    function upVoteCustomer(string memory _customerName) public returns (bool) {
        require(
            compareStringsbyBytes(
                _customerName,
                customers[_customerName].username
            ),
            "Customer doesn't exist. Use addCustomer to create new user"
        );

        require(
            up_votes[_customerName][msg.sender] == 0,
            "Customer has already been upvoted by you."
        );

        // update upVote count
        customers[_customerName].upVotes++;
        up_votes[_customerName][msg.sender] = 1;

        emit UpVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * Function to remove an up vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool
     */
    function removeUpVoteCustomer(string memory _customerName)
        public
        returns (bool)
    {
        require(
            compareStringsbyBytes(
                _customerName,
                customers[_customerName].username
            ),
            "Customer doesn't exist. Use addCustomer to create new user"
        );

        require(
            up_votes[_customerName][msg.sender] == 1,
            "Customer hasn't been upvoted by you. use upVoteCustomer"
        );

        // update upVote count
        customers[_customerName].upVotes--;
        up_votes[_customerName][msg.sender] = 0;

        emit RemoveUpVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * Function to add a new down vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool
     */
    function downVoteCustomer(string memory _customerName)
        public
        returns (bool)
    {
        require(
            compareStringsbyBytes(
                _customerName,
                customers[_customerName].username
            ),
            "Customer doesn't exist. Use addCustomer to create new user"
        );

        require(
            down_votes[_customerName][msg.sender] == 0,
            "Customer has already been down voted by you."
        );

        // update downVote count
        customers[_customerName].downVotes++;
        down_votes[_customerName][msg.sender] = 1;

        emit DownVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * Function to remove a down vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool
     */
    function removeDownVoteCustomer(string memory _customerName)
        public
        returns (bool)
    {
        require(
            compareStringsbyBytes(
                _customerName,
                customers[_customerName].username
            ),
            "Customer doesn't exist. Use addCustomer to create new user"
        );

        require(
            down_votes[_customerName][msg.sender] == 1,
            "Customer hasn't been down voted by you. Use downVoteCustomer."
        );

        // update downVote count
        customers[_customerName].downVotes--;
        down_votes[_customerName][msg.sender] = 0;

        emit RemoveDownVoteCustomer(_customerName, msg.sender);
        return true;
    }

    // source: https://ethereum.stackexchange.com/questions/45813/compare-strings-in-solidity
    function compareStringsbyBytes(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
