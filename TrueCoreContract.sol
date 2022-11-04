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

    // Metadata, Song Details
    uint256 private trackCounter = 0;

    // TrackTestName, Pop, Artist1, Composer1, Publish1, Owner1, 2020, 2020
    struct track {
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

    function ViewContractDetails() public pure returns (
        uint256 _PaymentRate,
        uint256 _PerViewCountBlock,

        uint256 _IssuerFee,
        uint256 _HolderFee,
        uint256 _AcceptorFee,

        uint256 _ContractEnd,
        uint256 _ContractStart,

        bool  _issuerApproval,
        bool _holderApproval,
        bool _acceptorApproval,
        bool _ContractApprovalVal
    ) {
        return (
            _PaymentRate,
            _PerViewCountBlock,

            _IssuerFee,
            _HolderFee,
            _AcceptorFee,

            _ContractEnd,
            _ContractStart,

            _issuerApproval,
            _holderApproval,
            _acceptorApproval,
            _ContractApprovalVal
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

    // Set the contract start end date
    function contractStartEnd(uint startdate, uint enddate) public {
        require (ContractApproval == false, "Contract already approved, no edits allowed");
        require (msg.sender == holder, "Only Holder can set contract start end date");

        require (startdate > block.timestamp && enddate > block.timestamp, "Start or end date has past");
        require (startdate > enddate, "Start must be more than end date");

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

        ContractApproval == true;

        emit OutputMessage("Contract Approved");
    }
}
