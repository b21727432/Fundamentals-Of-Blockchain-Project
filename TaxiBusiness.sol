//Ali kayadibi 21727432

pragma solidity 0.4.25;

contract Business{
    
    struct Participant {
        address addr;
		uint accountBalance;
    }
    
    struct TaxiDriver {
        address addr;
		uint accountBalance;
		uint salary;
		uint32 lastPaid;
    }
    
    struct ProposedCar{
        uint32 proposedCarID;
        uint price;
        uint32 offerValidTime;
    }
    
    struct PurchaseProposal{
        ProposedCar carForParticipants;
        mapping(address=>bool) participantsVoted;
        uint8 yesCount;
    }
    struct RepurchaseProposal{
        ProposedCar carForDealer;
        mapping(address=>bool) participantsVoted;
        uint8 yesCount;
    }
    struct DriverProposal{
        TaxiDriver exdriver;
        mapping(address=>bool) participantsVoted;
        uint8 yesCount;
    }
    
    address public manager;

    Participant[] public participants;
    
    TaxiDriver public driver;
    
    DriverProposal newDriver;
    
    address public dealer;
    
	uint32 public carID;
	
	ProposedCar public carProposal;
	
	PurchaseProposal purchaseProposal;
	
	RepurchaseProposal repurchaseProposal;
	
    uint32 public carExpensePaid;
    
	uint32 dividendLastPaid;
	
	modifier onlyManager(){
        require(msg.sender == manager, "Only manager can access");
        _;
    }

    modifier onlyDealer(){
        require(msg.sender == dealer, "Only dealer can access");
        _;
    }

    modifier onlyDriver(){
        require(msg.sender == driver.addr, "Only driver can access");
        _;
    }
    
    function getTime() public view returns(uint32){
        return uint32(now);
    }

    constructor() public {
		manager = msg.sender;
    }
    
    function join() public payable{
        require(participants.length < 9, "Maximum 9 participants.");
        require(msg.value == 100 ether, "Must send exactly 100 ether to join.");

        Participant memory newParticipant = Participant({
            addr: msg.sender,
            accountBalance: 0
        });
        participants.push(newParticipant);
        
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function setCarDealer(address dealerAddr) public onlyManager{
        dealer = dealerAddr;
	}
	
	
	function purchasePropose(uint32 carId, uint price, uint32 validTime) public onlyDealer{
    	ProposedCar memory car = ProposedCar({
    	    proposedCarID: carId,
    	    price: price,
    	    offerValidTime: validTime
    	});
        purchaseProposal.carForParticipants = car;
        purchaseProposal.yesCount = 0;
	}
	
	function approvePurchaseCar() public{
	    //require(participantJoinedFlag[msg.sender], "You are not a participant");
        require(purchaseProposal.carForParticipants.offerValidTime >= now, "You are late");
        require(!purchaseProposal.participantsVoted[msg.sender], "You are already voted");

        purchaseProposal.participantsVoted[msg.sender] = true;
        purchaseProposal.yesCount++;
	}
	
	function purchaseCar() public payable onlyManager{
        require(msg.value == purchaseProposal.carForParticipants.price, "Send the car value.");
        require(purchaseProposal.yesCount > participants.length / 2, "Not enough votes");
        require(address(this).balance >= purchaseProposal.carForParticipants.price, "Get some money first");
        
        dealer.transfer(purchaseProposal.carForParticipants.price);

        carID = purchaseProposal.carForParticipants.proposedCarID;

        carProposal.offerValidTime = 0;
	}
    function RepurchaseCarPropose(uint32 carId, uint price, uint32 validTime) public onlyDealer{
        ProposedCar memory car = ProposedCar({
    	    proposedCarID: carId,
    	    price: price,
    	    offerValidTime: validTime
    	});
        repurchaseProposal.carForDealer = car;
        repurchaseProposal.yesCount = 0;
    }
    function approveSellProposal() public{
        require(repurchaseProposal.carForDealer.offerValidTime >= now, "Too late");
        require(!repurchaseProposal.participantsVoted[msg.sender], "Can only vote once.");

        repurchaseProposal.participantsVoted[msg.sender] = true;
        repurchaseProposal.yesCount++;
	}
	
	function sellCar() public payable onlyDealer{
	    require(msg.value == repurchaseProposal.carForDealer.price, "Send the car value.");
        require(repurchaseProposal.yesCount > participants.length / 2, "Not enough vote");
        require(dealer.balance >= repurchaseProposal.carForDealer.price, "Broke dealer get some money");
        
        carID = 0;

        delete purchaseProposal;
	}
	
	function proposeDriver(address addr, uint salary)public onlyManager{
	    TaxiDriver memory exdriver1 = TaxiDriver({
    	    addr : addr,
    	    accountBalance: 0,
		    salary : salary,
		    lastPaid : 0
    	});
        newDriver.exdriver = exdriver1;
        newDriver.yesCount = 0;
	}
	
	function approveDriver() public{
	    require(!newDriver.participantsVoted[msg.sender], "Can only vote once.");

        newDriver.participantsVoted[msg.sender] = true;
        newDriver.yesCount++;
	}
	
	function setDriver() public onlyManager{
	    require(newDriver.yesCount > participants.length / 2, "Not enough votes");
        driver = newDriver.exdriver;
	}
	
	function fireDriver() public onlyManager{
	    
	    driver.accountBalance += driver.salary;

	    delete driver;
	}
	
	function getCharge() public payable{
	    require(msg.value>0, "No free rides");
	}
	
	function paySalary() public onlyManager{
        require(now - driver.lastPaid > 720*3600, "1 ay bekle");
	    driver.accountBalance += driver.salary;
	    driver.lastPaid = uint32(now);
    }
    
	function getSalary() public onlyDriver{
        require(driver.accountBalance > 0, "Driver balance is zero.");
        uint tmpBalance = driver.accountBalance;
        driver.accountBalance = 0;
        driver.addr.transfer(tmpBalance);
	}
	
	function carExpenses() public onlyManager{
        // check if the last time the expenses were paid was more than 6 months ago
        // 15778800: 6 months in seconds
        require(now - 4320*3600 > carExpensePaid, "6 ay bekle");
        dealer.transfer(10 ether);
        carExpensePaid = uint32(now);
	}
	
	function payDividend() public onlyManager{
	    require(now - 4320*3600 > dividendLastPaid, "You already got your money");
	    uint amountToBeShared = address(this).balance;
        if(now - carExpensePaid > 4320*3600){
            amountToBeShared -= 10 ether;
        }
        if(now - driver.lastPaid > 720*3600)
            amountToBeShared -= driver.salary;
        uint sharePerParticipant = amountToBeShared / participants.length;
        for(uint8 i=0; i<participants.length; i++){
            participants[i].accountBalance += sharePerParticipant;
        }
	}
	
	function getDividend() public{
        for(uint8 i=0; i<participants.length; i++){
            if(participants[i].addr == msg.sender){
                assert(address(this).balance >= participants[i].accountBalance);
                participants[i].accountBalance = 0;
                msg.sender.transfer(participants[i].accountBalance);
                break;
            }
        }
	}

}