pragma solidity ^0.8.17;

contract TrueCoreContract {

    // Addresses
    // TrueCore
    address private issuer; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

    // Spotify and other hosting company
    address private holder; // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

    // Solo Artist or the main firm
    address private acceptor; // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

    // Fees
    uint256 private PaymentRate;
    uint256 private ViewCount;

    uint256 private IssuerFee = 0;
    uint256 private HolderFee = 0;
    uint256 private AcceptorFee = 0;

    // Song Details
    // Meta Data
    string[] private SongMeta;

    // Approval Status
    bool private issuerApproval = false;
    bool private holderApproval = false;
    bool private acceptorApproval = false;
    bool private ContractApproval = false;

    event StatusChanged(address id, bool latestStatus, uint256 timestamp); 

    // Wallet
    uint256 private IssuerWalletBalance;
    uint256 private HolderWalletBalance;
    uint256 private AcceptorWalletBalance;

    // MISC
    uint256 private issuanceTime;
    uint256 private ContractEnd;
    uint256 private ContractStart;

    event OutputMessage(string m);

    // External Party
    uint256 private externalPartyCounter = 0;

    struct externalParty {
        string PartyName;
        uint256 fee;
        uint256 PartyWalletBalance;
        bool isExist;
    }

    mapping(address => externalParty) externalParties;
    address[] public externalPartiesArray;

    constructor(
        address issuerVal,
        address holderVal,
        address acceptorVal
    ) {
        require (tx.origin == issuerVal, "Only TuneCore can issue contract");
        issuer = issuerVal;
        holder = holderVal;
        acceptor = acceptorVal;
    }

    function getGeneralInfo() public view returns (
        address issuerVal,
        address holderVal,
        address acceptorVal,
        bool ContractApprovalVal
    ) {
        return (
            issuer,
            holder,
            acceptor,
            ContractApproval
        );
    }

    // View wallet Balance
    function getWalletBalance() public view returns (uint256 balance) {
        if (msg.sender == holder) {
            return (HolderWalletBalance);
        } else if (msg.sender == issuer) {
            return (IssuerWalletBalance);
        } else if (msg.sender == acceptor) {
            return (AcceptorWalletBalance);
        } else {
            require (externalParties[msg.sender].isExist, "No User of Wallet Found");
            return(externalParties[msg.sender].PartyWalletBalance);
        }
    }

    // Adding additional external parties
    function addParty(string memory PartyName, uint256 fee) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");

        require (checkTotalFee(fee) == false, "Rates are about 100% error");

        externalParties[msg.sender].PartyName = PartyName;
        externalParties[msg.sender].fee = fee;
        externalParties[msg.sender].isExist = true;

        externalPartiesArray.push(msg.sender);

        // When there is new party, approval gets reset
        resetApproval();
    }

    // Removal Still not working
    // Removing additional external parties
    // function removeParty(address PartyAddress) public {
    //     require (ContractApproval == false, "Contract already approved, no edits allowed");

    //     require (msg.sender == acceptor || msg.sender == issuer, "Only Issuer or Accept can remove additional parties");

    //     delete externalParties[PartyAddress];

    //     for (uint256 i = 0; i < externalPartiesArray.length; ++i) {
    //         if (externalPartiesArray[i] == PartyAddress) {

    //             for (uint x = i; i< externalPartiesArray.length-1; i++){
    //                 externalPartiesArray[x] = externalPartiesArray[x+1];
    //             }
    //             delete externalPartiesArray[externalPartiesArray.length-1];
    //             externalPartiesArray.pop();


    //             delete externalPartiesArray[i];
    //             emit OutputMessage("Additional Party Removed");
    //             break;
    //         }
    //     }

    //     // When there is a party update, approval gets reset
    //     resetApproval();
    // }

    // Count how many external parties are there
    function count () view public returns(uint) {
        return externalPartiesArray.length;
    }

    // View how many external parties are there
    function GetAllStrings() view public returns(address[] memory){
        return externalPartiesArray;
    }

    // Set the rate of the fee each party takes
    function setFee(uint fee) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == holder || msg.sender == acceptor || msg.sender == issuer, "Only Issuer, Holder or Acceptor can set rates");

        // Validations
        require (checkTotalFee(fee) == false, "Rates are about 100% error");

        if (msg.sender == holder) {
            HolderFee = fee;
        } else if(msg.sender == issuer) {
            IssuerFee = fee;
        } else if(msg.sender == acceptor) {
            AcceptorFee = fee;
        }

        // Resets approval when rates are changed
        resetApproval();
    }

    // Holder and Acceptor Approval Area
    function setApprovalStatus(bool status) public {
        // uint approvalDate = block.timestamp;

        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == issuer || msg.sender == holder || msg.sender == acceptor, "Only Issuer, Holder or Acceptor can approve");

        // Check if they send the same status
        if (msg.sender == holder) {
            require (holderApproval != status, "Status is the same");
        } else if (msg.sender == acceptor) {
            require (acceptorApproval != status, "Status is the same");
        } else if (msg.sender == issuer) {
            require (issuerApproval != status, "Status is the same");
        }

        // Changes their approval status
        if (msg.sender == holder) {
            holderApproval = status;
        } else if (msg.sender == acceptor) {
            acceptorApproval = status;
        }

        // Set overall approval of contract to true if all accept
        if (issuerApproval == true && holderApproval == true && acceptorApproval == true) {
            ContractApproval = true;
        } else {
            ContractApproval = false;
            if (holderApproval != true) {
                emit OutputMessage("Pending Holder Approval");
            }

            if (acceptorApproval != true) {
                emit OutputMessage("Pending Acceptor Approval");
            }
        }
    }

    // Resets approval
    function resetApproval() private {
        holderApproval = false;
        acceptorApproval = false;
        issuerApproval = false;
    }

    // Validation check to ensure rate not > 100
    function checkTotalFee(uint fee) private view returns(bool){
        uint CheckFees = 0;
        CheckFees = fee + CheckFees + IssuerFee + HolderFee + AcceptorFee;
        for (uint256 i = 0; i < externalPartiesArray.length; ++i) {
            if (CheckFees > 100) {
                return true;
            } else {
                CheckFees += externalParties[externalPartiesArray[i]].fee;
            }
        }

        return false;
    }

    // Do function to check if all variables are inside !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
}
