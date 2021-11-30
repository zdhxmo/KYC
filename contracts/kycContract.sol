pragma solidity ^0.8.9;

contract kycContract {
    struct Customer {
        string username;
        // hash of the documents submitted by the customer
        string dataHash;
        // upvotes by other banks
        uint256 upVotes;
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

}
