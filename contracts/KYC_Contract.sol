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
        bool kycStatus;
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

    struct KYC_Request {
        // map KYC request to customer data
        string username;
        // hash that points to customer documents in secure storage
        string customerData;
        // unique account address of the bank
        address bankAddress;
    }

    // count of total banks in the network
    uint32 totalBanks;

    /* Mappings */

    // customer name to view customer details
    mapping(string => Customer) customers;

    // unique bank address to view bank details
    mapping(address => Bank) banks;

    // customer name to view KYC requests
    mapping(string => KYC_Request) KYC_requests;

    // keep track of up votes for the customer by all the banks in the network
    mapping(string => mapping(address => uint8)) up_votes;

    // keep track of down votes for the customer by all the banks in the network
    mapping(string => mapping(address => uint8)) down_votes;

    // make sure all bank registration numbers are unique
    mapping(string => bool) bank_registration_numbers;

    // keep track of banks added to the network
    mapping(address => bool) added_banks;

    // keep track of bank names added to the system
    mapping(string => bool) bank_names;

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

    event CustomerKYCStatus(string _customerName, bool _KYCStatus);

    event UpVoteCustomer(string _customerName, address bankAddress);
    event RemoveUpVoteCustomer(string _customerName, address bankAddress);

    event DownVoteCustomer(string _customerName, address bankAddress);
    event RemoveDownVoteCustomer(string _customerName, address bankAddress);

    event ReportBank(
        address _bankAddress,
        address reportingBank,
        bool isAllowedToVote
    );

    event AddBank(
        string _bankName,
        address _bankAddress,
        string _bankRegistration,
        uint32 _complaintsReported,
        bool _KYCPermission
    );

    event ModifyIfBankAllowedToVote(
        address _bankAddress,
        bool _isAllowedToVote
    );

    event RemoveBank(address _bankAddress);

    /**
     * Record a new KYC request on behalf of a customer
     * Bank is the sender of this request
     * @param _customerName The name of the customer for whom KYC is to be done
     * @param _customerData The hash of the customer data being requested
     * @return bool confirmation that KYC request was added
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
     * @return bool confirmation that KYC request was removed
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
     * @return struct Customer
     */
    function viewCustomer(string memory _customerName)
        public
        view
        returns (
            string memory,
            string memory,
            address,
            uint32,
            uint32
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
            customers[_customerName].validatorBankAddress,
            customers[_customerName].upVotes,
            customers[_customerName].downVotes
        );
    }

    /**
     * Add a new customer
     * @param _customerName Name of the customer
     * @param _customerData Hash of the customer docs
     * @return bool confirmation that user was added
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

        // initiate KYC request on creation of customer
        addKYCRequest(_customerName, _customerData);

        emit AddCustomer(_customerName, _customerData, msg.sender);
        return true;
    }

    /**
     * Modify customer data
     * @param _customerName Name of the customer
     * @param _newCustomerData New hash of the updated docs
     * @return bool confirmation that user was modified
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
     * Function to change the KYC status of customer based on up or down votes
     * @param _customerName Name of the customer to be upvoted
     * @return bool true if KYC status was updated
     */
    function customerKYCStatus(string memory _customerName)
        public
        returns (bool)
    {
        // solidity doesn't support float or rational numbers
        // hence we multiply 100 to both sides of the equation
        uint32 condition1 = customers[_customerName].downVotes * 100;
        uint32 condition2 = 33 * totalBanks;

        if (condition1 < condition2) {
            if (
                customers[_customerName].upVotes >
                customers[_customerName].downVotes
            ) {
                customers[_customerName].kycStatus = true;
            } else {
                customers[_customerName].kycStatus = false;
            }
        }

        emit CustomerKYCStatus(
            _customerName,
            customers[_customerName].kycStatus
        );
        return true;
    }

    /**
     * Function to add a new up vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool confirmation that up votes were updated
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
            compareStringsbyBytes(
                KYC_requests[_customerName].username,
                _customerName
            ),
            "Cannot upvote as no KYC exists for this customer yet."
        );

        require(
            up_votes[_customerName][msg.sender] == 0,
            "Customer has already been upvoted by you."
        );

        // update upVote count
        customers[_customerName].upVotes++;
        up_votes[_customerName][msg.sender] = 1;

        // update customer KYC status in light of vote update
        customerKYCStatus(_customerName);

        emit UpVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * Function to remove an up vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool confirmation that up votes were updated
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
            compareStringsbyBytes(
                KYC_requests[_customerName].username,
                _customerName
            ),
            "Cannot remove upvote as no KYC exists for this customer yet."
        );

        require(
            up_votes[_customerName][msg.sender] == 1,
            "Customer hasn't been upvoted by you. use upVoteCustomer"
        );

        // update upVote count
        customers[_customerName].upVotes--;
        up_votes[_customerName][msg.sender] = 0;

        // update customer KYC status in light of vote update
        customerKYCStatus(_customerName);

        emit RemoveUpVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * Function to add a new down vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool confirmation that down votes were updated
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
            compareStringsbyBytes(
                KYC_requests[_customerName].username,
                _customerName
            ),
            "Cannot downvote as no KYC exists for this customer yet."
        );

        require(
            down_votes[_customerName][msg.sender] == 0,
            "Customer has already been down voted by you."
        );

        // update downVote count
        customers[_customerName].downVotes++;
        down_votes[_customerName][msg.sender] = 1;

        // update customer KYC status in light of vote update
        customerKYCStatus(_customerName);

        emit DownVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * Function to remove a down vote for a customer
     * @param _customerName Name of the customer to be upvoted
     * @return bool confirmation that down votes were updated
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
            compareStringsbyBytes(
                KYC_requests[_customerName].username,
                _customerName
            ),
            "Cannot remove downvote as no KYC exists for this customer yet."
        );

        require(
            down_votes[_customerName][msg.sender] == 1,
            "Customer hasn't been down voted by you. Use downVoteCustomer."
        );

        // update downVote count
        customers[_customerName].downVotes--;
        down_votes[_customerName][msg.sender] = 0;

        // update customer KYC status in light of vote update
        customerKYCStatus(_customerName);

        emit RemoveDownVoteCustomer(_customerName, msg.sender);
        return true;
    }

    /**
     * View bank information
     * @param _bankAddress Unique address of the bank
     * @return struct Bank
     */
    function getBankDetails(address _bankAddress)
        public
        view
        returns (
            string memory,
            address,
            uint32,
            uint32,
            bool,
            string memory
        )
    {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank address is incorrect. No such record exists"
        );

        return (
            banks[_bankAddress].name,
            banks[_bankAddress].ethAddress,
            banks[_bankAddress].complaintsReported,
            banks[_bankAddress].KYC_count,
            banks[_bankAddress].isAllowedToVote,
            banks[_bankAddress].regNumber
        );
    }

    /**
     * Report a complaint against a bank
     * @param _bankAddress Unique address of the bank
     * @return bool confirmation that report was submitted
     */
    function reportBank(address _bankAddress) public returns (bool) {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank address is incorrect. No such record exists"
        );

        // update count of the complaints reported
        banks[_bankAddress].complaintsReported++;

        // solidity doesn't support float or rational numbers
        // hence we multiply 100 to both sides of the equation
        uint32 condition1 = banks[_bankAddress].complaintsReported * 100;
        uint32 condition2 = 33 * totalBanks;
        if (condition1 > condition2) {
            banks[_bankAddress].isAllowedToVote = false;
        }

        emit ReportBank(
            _bankAddress,
            msg.sender,
            banks[_bankAddress].isAllowedToVote
        );
        return true;
    }

    /**
     * View total number of bank complaints
     * @param _bankAddress unique address of the bank
     * @return uint32 total number of bank complaints
     */
    function getBankComplaints(address _bankAddress)
        public
        view
        returns (uint32)
    {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank address is incorrect. No such record exists"
        );

        return banks[_bankAddress].complaintsReported;
    }

    /**
     * Add a new bank to the network
     * @param _bankName name of the bank
     * @param _bankAddress unique address of the bank
     * @param _bankRegistration unique registration number of the bank
     * @return bool New bank has been added to the network
     */
    function addBank(
        string memory _bankName,
        address _bankAddress,
        string memory _bankRegistration
    ) public onlyAdmin returns (bool) {
        require(
            added_banks[_bankAddress] == false,
            "This bank has already been added"
        );

        // require a unique registration number
        require(
            bank_registration_numbers[_bankRegistration] == false,
            "This registration number has been taken. Please enter another one."
        );

        require(
            bank_names[_bankName] == false,
            "A bank of this name already exists in the network"
        );

        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].complaintsReported = 0;
        banks[_bankAddress].KYC_count = 0;
        banks[_bankAddress].isAllowedToVote = true;
        banks[_bankAddress].regNumber = _bankRegistration;

        // update registration number and name mappings
        bank_registration_numbers[_bankRegistration] = true;
        added_banks[_bankAddress] = true;
        bank_names[_bankName] = true;

        // update count of total banks in the network
        totalBanks++;

        emit AddBank(_bankName, _bankAddress, _bankRegistration, 0, true);
        return true;
    }

    /**
     * Modify if a bank is allowed to vote in the KYC process
     * @param _bankAddress unique address of the bank
     * @param _isAllowedToVote boolean value, true if bank is allowed, false if not
     * @return bool true if bank's voting rights were revoked by admin
     */

    function modifyIfBankAllowedToVote(
        address _bankAddress,
        bool _isAllowedToVote
    ) public onlyAdmin returns (bool) {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank address is incorrect. No such record exists"
        );

        banks[_bankAddress].isAllowedToVote = _isAllowedToVote;

        emit ModifyIfBankAllowedToVote(_bankAddress, _isAllowedToVote);
        return true;
    }

    /**
     * Remove a bank from the network
     * @param _bankAddress unique address of the bank
     * @return bool true if bank has been removed from the network by admin
     */
    function removeBank(address _bankAddress) public onlyAdmin returns (bool) {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank address is incorrect. No such record exists"
        );

        delete banks[_bankAddress];

        emit RemoveBank(_bankAddress);
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
