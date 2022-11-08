# ArtistPaymentSmartContract

## Basic requirements
- Unique Issuer Address (Tunecore)
- Unique Holder Address (Spotify/YouTube, etc)
- Unique Acceptor Address (Artist)
- Any other additional parties Address (Have to be unique)

# Contractual Instructions
This section will be used to create the contract related side of things

## Step 1: Creating of contract
This step will be used to create the contract
- Using the Issuer Account, input ISSUERVAL, HOLDERVAL, ACCEPTORVAL (Their address)
- Click Deploy

Note: Only Issuer can deploy the contract

## Step 2: Adding of additional parties
This step is used to create any additional parties into the contract. Parties such as publisher company, or any othe composers who are getting a cut in the payment
- Select a Unique Account
- Enter the "PartyName" and "Fee" (Percentage, wholenumber) into "addParty"

### Testing values
- "addParty": John, 10

Note: Only an unique account can add themselves as the additional party

## Step 3: Setting of Meta Data (Artist) (Acceptor)
This step is for the artist to input the song's meta data into the system. It will act as the identity for the song
- Using the Acceptor Account, enter the meta data into "addUpdateMetaData" function

### Testing values
- "addUpdateMetaData": TrackTestName, Pop, Artist1, Composer1, Publish1, Owner1, 1514764800, 1514764800

Note: Meta Data consist of: Track Name, Genre, Primary Artist, Composer, Publisher, Master Recording Owner, Year of Composition, Year of Recording
Note2: For Year of Composition and Year of Recording, date have to be converted to SECONDS

## Step 4: Setting of Contract Details (Spotify/YouTube, etc) (Holder)
This step is for the holder to set all the contractual details that will determine the payout and contract duration
- Using the Holder Account, Holders will be setting a few contract details
-- "setViewCountBlock" - Setting how many view count consist in a single block for rate calculation
-- "setPaymentRate" - Setting of how much the Holder will pay out per view block
-- "contractStartEnd" - Specify when the contract start and end*

### Testing values
- "setViewCountBlock": 100
- "setPaymentRate": 10
- "contractStartEnd": 9514764800, 9614764900

Note: Dates have to be in seconds and must be after the current date time

## Step 5: Setting of Fees (Issuer, Holder)
This step will enable the parties to set the fees for their cut in the payment
- Issuer Account
-- "setFee"
- Holder Account
-- "setFee"

### Testing values
- "setFee": 10

Note: Acceptor fees is not included as the acceptor will take the remaining amount after the fees

## Step 6: Accepting of Contract (Issuer, Holder, Acceptor)
This step is for the main 3 parties to accept the contract
- Issuer Account
-- "setApprovalStatus"
- Holder Account
-- "setApprovalStatus"
- Acceptor Account
-- "setApprovalStatus"

### Testing values
- "setApprovalStatus": true

Note: In an event that any contractual details are changed, the approval status for all parties will be false, thus requiring all users to approval it again
Note2: After all 3 parties accept, the contract will be automatically approved and no other contractual details changes can be made

# Payment Instruction
This section will be used for the payment side of things

## Step 1: Making of payment by the Holder
This step is for the holder to make payment to the Issuer
- Using the Holder Account, enter the amount of view count that the song has, to make the payment
-- "MakePayment"

### Testing values
- "MakePayment": 100000

## Step 2: Confirming of the payment by the Issuer
This step is for the issuer to confirm that they have physically received the payment from the Holder outside of the blockchain
- Using Issuer Account, enter the amount that has been received from the Holder's transfer outside of the blockchain
-- "ConfirmPayment"

### Testing values
- "ConfirmPayment": 100000

Note: Payment can be done in batches
Note2: If there are existing payments not cleared by the Issuer, Holder cannot initiate any new payment within the blockchain

## Step 3: Transfering to wallets of the related party (Automatic)
Once any payment has been confirmed, the SC will automatically transfer the money based on their rates into their individual wallets according to the contract.

# Withdrawl Instruction
This section will be used for the parties to withdraw out the money

## Step 1: Party initiates the withdrawal of money
- Using any party that is currently in the contract
--"withdraw"

### Testing values
- "withdraw": 100

Once withdrawal has been initated, the balance will be reflected after the withdrawal sum and Tunecore will initate the payment to the party outside of the blockchain

# Viewing of Values Instruction
This section will explain what the viewing functions are for

## "Count"
Displays how many additional parties there are in the contract

## "externalPartiesArray"
Displays the address of the selected position of address in the external party (Takes in an integer)

## "GetAllStrings"
Displaying all the address of all the external parties in the contract

## "getWalletBalance"
Change to the person's account which you want to get the balance from and call this function

## "RemainingPayment"
Shows how much payment has/has not been paid

## "ViewContractDetails"
Shows all the contract details such as:
- Payment Rate
- View Block
- Issuer Fee
- Holder Fee
- Acceptor Fee (Values derived after minusing all the fees)
- Contract End Date
- Contract Start Date
- Issuer Approval Status
- Holder Approval Status
- Acceptor Approval Status
- Overall Contract Approval Status

## "ViewMetadata"
Shows the song metadata
- Track name
- Genre
- Primary Artist
- Composer
- Publisher
- Master Recording Owner
- Year of Composition
- Year of Recording

## "ViewPartiesDetails"
Shows the address of Issuer, Holder, Acceptor
