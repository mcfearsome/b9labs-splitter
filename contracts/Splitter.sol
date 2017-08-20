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

    function kill() onlyOwner {
        suicide(owner);
    }
}

contract BalanceManager {
    mapping(address => uint) balances;
    event WithdrawCompleted(address indexed receiver, uint amount);

    function balanceAdd(address toAddress, uint amount) internal {
      balances[toAddress] += amount;
    }

    function balanceSubtract(address fromAddress, uint amount) internal {
      balances[fromAddress] -= amount;
      assert(balances[fromAddress] >= 0);
    }

    function balanceTransfer(address fromAddress, address toAddress, uint amount) internal {
      balanceSubtract(fromAddress, amount);
      balanceAdd(toAddress, amount);
    }

    function drain(address fromAddress) internal returns(uint) {
      uint currentAmount = balances[fromAddress];
      balances[fromAddress] = 0;
      return currentAmount;
    }

    function withdraw() {
        require(balances[msg.sender] > 0);
        uint toSend = drain(msg.sender);
        msg.sender.transfer(toSend);
        WithdrawCompleted(msg.sender, toSend);
    }
}

contract Splitter is Owned, BalanceManager {
    uint numGroups = 1;
    mapping(uint => address[3]) public splitGroups;
    mapping(address => uint) public splitGroupsByAddress;
    event SplitGroupCreated(address indexed creator, address[3] members);
    event SplitOccurred(address indexed splitter, address[2] receivers, uint amount);

    modifier senderPartOfGroup {
        require(isGroupMember(msg.sender));
        _;
    }

    function createSplitGroup(address[2] others) {
        // Ensure sender isn't in a group already
        require(!isGroupMember(msg.sender));
        require(others[0] != others[1]);
        for(uint8 j = 0; j < 2; j++) {
            require(others[j] != msg.sender);
            require(others[j] != 0x0);
            // Ensure others aren't in a group already
            require(!isGroupMember(others[j]));
        }
        address[3] memory addresses = [others[0], others[1], msg.sender];
        uint theIndex = numGroups++;
        splitGroups[theIndex] = addresses;

        for(uint8 i = 0;  i < 3; i++) {
            splitGroupsByAddress[addresses[i]] = theIndex;
        }
        SplitGroupCreated(msg.sender, addresses);
    }

    function split() payable senderPartOfGroup {
        address[3] memory members = splitGroups[splitGroupsByAddress[msg.sender]];
        address[2] memory receivers;
        uint8 receiverIndex = 0;
        uint half = msg.value / 2;

        balanceAdd(msg.sender, msg.value);
        for(uint8 i = 0; i < members.length; i++) {
            if(members[i] != msg.sender) {
                receivers[receiverIndex++] = members[i];
                balanceTransfer(msg.sender, members[i], half);
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

    function isGroupMember(address forAddress) constant returns (bool) {
      if(splitGroupsByAddress[forAddress] == 0) { return false; }
      return true;
    }

    function() payable senderPartOfGroup {
        split();
    }
}
