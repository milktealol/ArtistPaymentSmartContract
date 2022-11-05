pragma solidity ^0.8.17;

contract TrueCoreContract {

    // Addresses
    // TrueCore
    address private issuer;

    // Spotify and other hosting company
    address private holder;

    // Solo Artist or the main firm
    address private acceptor;

    // Fees
    uint256 private PaymentRate;
    uint256 private PerViewCountBlock;

    uint256 private IssuerFee = 0;
    uint256 private HolderFee = 0;
    uint256 private AcceptorFee = 0;

    // Approval Status
    bool private issuerApproval = false;
    bool private holderApproval = false;
    bool private acceptorApproval = false;
    bool private ContractApproval = false;

    // Wallet
    uint256 private IssuerWalletBalance;
    uint256 private HolderWalletBalance;
    uint256 private AcceptorWalletBalance;

    // Payment
    bool paymentPending = false;
    uint256 TotalPayable;

    // Contract Start End Date
    uint256 private ContractEnd;
    uint256 private ContractStart;

    // Printing out of message
    event OutputMessage(string m);

    // Metadata, Song Details Mapping
    struct track { // TrackTestName, Pop, Artist1, Composer1, Publish1, Owner1, 2020, 2020
        string TrackName;
        string Genre;
        string PrimaryArtist;
        string Composer;
        string Publisher;
        string MasterRecordingOwner;
        uint256 YearOfComposition;
        uint256 YearOfRecording;
    }

    mapping(address => track) tracks;
    address[] public tracksArray;

    // External Party Mapping
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

    function ViewPartiesDetails() public view returns (
        address issuerVal,
        address holderVal,
        address acceptorVal
    ) {
        return (
            issuer,
            holder,
            acceptor
        );
    }

    function ViewContractDetails() public view returns (
        uint256 PaymentRateVal,
        uint256 PerViewCountBlockVal,

        uint256 IssuerFeeVal,
        uint256 HolderFeeVal,
        uint256 AcceptorFeeVal,

        uint256 ContractEndVal,
        uint256 ContractStartVal,

        bool issuerApprovalVal,
        bool holderApprovalVal,
        bool acceptorApprovalVal,
        bool ContractApprovalVal
    ) {
        return (
            PaymentRate,
            PerViewCountBlock,

            IssuerFee,
            HolderFee,
            AcceptorFee,

            ContractEnd,
            ContractStart,

            issuerApproval,
            holderApproval,
            acceptorApproval,
            ContractApproval
        );
    }

    function ViewMetadata() public view returns (
        string memory TrackName, 
        string memory Genre, 
        string memory PrimaryArtist, 
        string memory Composer, 
        string memory Publisher, 
        string memory MasterRecordingOwner, 
        uint256 YearOfComposition, 
        uint256 YearOfRecording
    ) {
        return (
            tracks[acceptor].TrackName,
            tracks[acceptor].Genre,
            tracks[acceptor].PrimaryArtist,
            tracks[acceptor].Composer,
            tracks[acceptor].Publisher,
            tracks[acceptor].MasterRecordingOwner,
            tracks[acceptor].YearOfComposition,
            tracks[acceptor].YearOfRecording
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

    function RemainingPayment() public view returns (
        uint256 TotalPayableVal
    ) {
        return (
            TotalPayable
        );
    }

    // Adding additional external parties
    function addParty(string memory PartyName, uint256 fee) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender != holder && msg.sender != acceptor && msg.sender != issuer, "Issuer, Holder or Acceptor cannot set be the additional party");

        require (checkTotalFee(fee) == false, "Rates are above 100% error");

        externalParties[msg.sender].PartyName = PartyName;
        externalParties[msg.sender].fee = fee;
        externalParties[msg.sender].isExist = true;

        externalPartiesArray.push(msg.sender);

        // When there is new party, approval gets reset
        resetApproval();
    }

    // Count how many external parties are there
    function count () view public returns(uint) {
        return externalPartiesArray.length;
    }

    // View how many external parties are there
    function GetAllStrings() view public returns(address[] memory){
        return externalPartiesArray;
    }

    // Adding or Updating Metadata
    function addUpdateMetaData(
        string memory TrackName, 
        string memory Genre, 
        string memory PrimaryArtist, 
        string memory Composer, 
        string memory Publisher, 
        string memory MasterRecordingOwner, 
        uint256 YearOfComposition, 
        uint256 YearOfRecording
        ) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");

        require (msg.sender == acceptor, "Only Acceptor can set Metadata for song");

        tracks[msg.sender].TrackName = TrackName;
        tracks[msg.sender].Genre = Genre;
        tracks[msg.sender].PrimaryArtist = PrimaryArtist;
        tracks[msg.sender].Composer = Composer;
        tracks[msg.sender].Publisher = Publisher;
        tracks[msg.sender].MasterRecordingOwner = MasterRecordingOwner;
        tracks[msg.sender].YearOfComposition = YearOfComposition;
        tracks[msg.sender].YearOfRecording = YearOfRecording;

        // When there is new party, approval gets reset
        resetApproval();
    }

    // Set the Payment Rate Per View of song
    function setPaymentRate(uint rate) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == holder, "Only Holder can set rates");

        PaymentRate = rate;

        // Resets approval when rates are changed
        resetApproval();
    }

    // Set the Payment Rate Per View of song
    function setViewCountBlock(uint ViewBlock) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == holder, "Only Holder can set rates");

        PerViewCountBlock = ViewBlock;

        // Resets approval when rates are changed
        resetApproval();
    }

    // Set the rate of the fee each party takes
    function setFee(uint fee) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == holder || msg.sender == issuer, "Only Issuer, Holder or Acceptor can set rates");

        // Validations
        require (checkTotalFee(fee) == false, "Rates are about 100% error");

        if (msg.sender == holder) {
            HolderFee = fee;
        } else if(msg.sender == issuer) {
            IssuerFee = fee;
        }

        // Resets approval when rates are changed
        resetApproval();
    }

    // Set the contract start end date
    function contractStartEnd(uint startdate, uint enddate) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == holder, "Only Holder can set contract start end date");

        require (startdate > block.timestamp && enddate > block.timestamp, "Start or end date has past");
        require (startdate < enddate, "Start must be more than end date");

        ContractStart = startdate;
        ContractEnd = enddate;

        // Resets approval when rates are changed
        resetApproval();
    }

    // Approval Area
    function setApprovalStatus(bool status) public {

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
        } else if (msg.sender == issuer) {
            issuerApproval = status;
        }

        // Set overall approval of contract to true if all accept
        if (issuerApproval == true && holderApproval == true && acceptorApproval == true) {
            finalChecks();
        } else {
            ContractApproval = false;
            if (holderApproval != true) {
                emit OutputMessage("Pending Holder Approval");
            }

            if (acceptorApproval != true) {
                emit OutputMessage("Pending Acceptor Approval");
            }

            if (issuerApproval != true) {
                emit OutputMessage("Pending Issuer Approval");
            }
        }
    }

    // Payment FUNCTIONS ---------------------------------------------------------------------------------------------------
    function MakePayment(uint256 viewCount) public {
        require (msg.sender == holder, "Only Holder can make payment");
        require (ContractApproval == true, "Contract have to be completed before payment is made");
        require (paymentPending == false, "There is a payment pending, please contact issuer to approve before proceeding");
        require (viewCount > PerViewCountBlock, "Value have to be higher than per view count block");

        TotalPayable = viewCount / PerViewCountBlock * PaymentRate;

        paymentPending = true;
    }

    // Issuer to confirm payment receipt
    function ConfirmPaymentAmount(uint256 paymentAmountReceived) public {
        require (msg.sender == issuer, "Only Issuer can confirm payment receipt");
        require (ContractApproval == true, "Contract have to be completed before payment is made");
        require (paymentAmountReceived > 0, "Please input accurate amount");


        // Do spliting of bill
        splitPayment(paymentAmountReceived);

        TotalPayable -= paymentAmountReceived;

        if (TotalPayable <= 0) {
            paymentPending = false;
        }

    }

    // Withdraw FUNCTIONS ---------------------------------------------------------------------------------------------------
    function withdraw(uint256 WithdrawAmount) public {
        if (msg.sender == holder) {
            HolderWalletBalance -= WithdrawAmount;
        } else if (msg.sender == acceptor) {
            AcceptorWalletBalance -= WithdrawAmount;
        } else if (msg.sender == issuer) {
            IssuerWalletBalance -= WithdrawAmount;
        } else {
            require (externalParties[msg.sender].isExist, "No User of Wallet Found");

            externalParties[msg.sender].PartyWalletBalance = externalParties[msg.sender].PartyWalletBalance - WithdrawAmount;
            // for (uint256 i = 0; i < externalPartiesArray.length; ++i) {
            //     if (externalPartiesArray[i] == msg.sender) {
            //         uint256 currentBalance = externalParties[externalPartiesArray[i]].PartyWalletBalance;
            //         externalParties[externalPartiesArray[i]].PartyWalletBalance = currentBalance - WithdrawAmount;
            //         return;
            //     }
            // }

        }
    }

    // INTERNAL FUNCTIONS ---------------------------------------------------------------------------------------------------

    // Resets approval
    function resetApproval() private {
        holderApproval = false;
        acceptorApproval = false;
        issuerApproval = false;
    }

    // Validation check to ensure rate not > 100
    function checkTotalFee(uint fee) private view returns(bool){
        uint CheckFees = 0;
        CheckFees = fee + CheckFees + IssuerFee + HolderFee;
        for (uint256 i = 0; i < externalPartiesArray.length; ++i) {
            if (CheckFees > 100) {
                return true;
            } else {
                CheckFees += externalParties[externalPartiesArray[i]].fee;
            }
        }

        return false;
    }

    // Final checks if all required values are inside
    function finalChecks() private {
        require(issuerApproval == true && holderApproval == true && acceptorApproval == true, "Not all approved");
        require(
            bytes(tracks[acceptor].TrackName).length != 0 &&
            bytes(tracks[acceptor].Genre).length != 0 &&
            bytes(tracks[acceptor].PrimaryArtist).length != 0 &&
            bytes(tracks[acceptor].Composer).length != 0 &&
            bytes(tracks[acceptor].Publisher).length != 0 &&
            bytes(tracks[acceptor].MasterRecordingOwner).length != 0 &&
            tracks[acceptor].YearOfComposition != 0 &&
            tracks[acceptor].YearOfRecording != 0,
            "Metadata Missing");
        
        require(PaymentRate != 0, "Payment Rate Cannot Be Empty");
        require(PerViewCountBlock != 0, "Per View Count Cannot Be Empty");

        require(ContractStart != 0, "Contract Start Cannot Be Empty");
        require(ContractEnd != 0, "Contract End Cannot Be Empty");

        require(HolderFee > 0, "Please check Holder Fee");
        require(IssuerFee > 0, "Please check Issuer Fee");

        uint additionalFees = 0;
        for (uint256 i = 0; i < externalPartiesArray.length; ++i) {
            additionalFees += externalParties[externalPartiesArray[i]].fee;
        }

        AcceptorFee = 100 - HolderFee - IssuerFee - additionalFees;

        ContractApproval = true;

        emit OutputMessage("Contract Approved");
    }

    // Spliting of payment
    function splitPayment(uint256 paymentAmountReceived) private {
        IssuerWalletBalance += paymentAmountReceived / 100 * IssuerFee;
        HolderWalletBalance += paymentAmountReceived / 100 * HolderFee;
        AcceptorWalletBalance += paymentAmountReceived / 100 * AcceptorFee;

        for (uint256 i = 0; i < externalPartiesArray.length; ++i) {
            uint256 currentBalance = externalParties[externalPartiesArray[i]].PartyWalletBalance;
            externalParties[externalPartiesArray[i]].PartyWalletBalance = currentBalance + paymentAmountReceived / 100 * externalParties[externalPartiesArray[i]].fee;
        }
    }
}
