pragma solidity ^0.4.11;

contract Owned {
    address public owner;
    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract BalanceHolder {
    mapping(address => uint) balances;
    event WithdrawPerformed(address indexed receiver, uint amount);

    function withdraw() {
        require(balances[msg.sender] > 0);
        uint toSend = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(toSend);
        WithdrawPerformed(msg.sender, toSend);
    }
}

contract Splitter is Owned, BalanceHolder {
    uint numGroups;
    mapping(uint => address[3]) public splitGroups;
    mapping(address => uint) public splitGroupsByAddress;
    event SplitGroupCreated(address indexed creator, address[3] members);
    event SplitOccurred(address indexed splitter, address[2] receivers, uint amount);

    function createSplitGroup(address[2] others) {
        // Ensure sender isn't in a group already
        require(splitGroupsByAddress[msg.sender] == 0);
        require(others[0] != others[1]);
        for(uint8 j = 0; i < 2; i++) {
            require(others[j] != msg.sender);
            require(others[j] != 0x0);
            // Ensure others are'nt in a group already
            require(splitGroupsByAddress[msg.sender] == 0);
        }
        address[3] memory addresses = [others[0], others[1], msg.sender];
        uint theIndex = numGroups++;
        splitGroups[theIndex] = addresses;

        for(uint8 i = 0;  i < 3; i++) {
            splitGroupsByAddress[addresses[i]] = theIndex;
        }
        SplitGroupCreated(msg.sender, addresses);
    }

    function split() payable {
        require(splitGroupsByAddress[msg.sender] != 0);
        address[3] memory members = splitGroups[splitGroupsByAddress[msg.sender]];
        uint8 receiverIndex = 0;
        address[2] memory receivers;

        for(uint8 i = 0; i < members.length; i++) {
            if(members[i] != msg.sender) {
                receivers[receiverIndex++] = members[i];
                balances[members[i]] = msg.value / 2;
            }
        }
        SplitOccurred(msg.sender, receivers, msg.value);
    }

    function showGroupBalances(address forAddress) constant returns (address[3] members, uint[3] memberBalances) {
        members = splitGroups[splitGroupsByAddress[forAddress]];
        for(uint8 i = 0; i < members.length; i++) {
            memberBalances[i] = balances[members[i]];
        }
        return (members, memberBalances);
    }

    function kill() onlyOwner {
        suicide(owner);
    }

    function() payable {
        if(splitGroupsByAddress[msg.sender] != 0) {
            split();
        }
    }
}
