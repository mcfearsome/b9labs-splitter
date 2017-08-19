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

    function withdraw() {
        require(balances[msg.sender] > 0);
        uint toSend = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(toSend);
    }
}

contract Splitter is Owned, BalanceHolder {

    struct SplitGroup {
        address[3] groupMembers;
        bool isSet;
    }
    mapping(address => SplitGroup) public splitGroups;

    function createSplitGroup(address[2] others) {
        require(!splitGroups[msg.sender].isSet);
        for(uint8 j = 0; i < 2; i++) {
            require(others[j] != 0x0);
            require(!splitGroups[others[j]].isSet);
        }
        address[3] memory addresses = [others[0], others[1], msg.sender];
        for(uint8 i = 0;  i < 3; i++) {
            splitGroups[addresses[i]].isSet = true;
            splitGroups[addresses[i]].groupMembers = addresses;
        }
    }

    function split() payable {
        require(splitGroups[msg.sender].isSet);
        address[3] memory members = splitGroups[msg.sender].groupMembers;

        for(uint8 i = 0; i < members.length; i++) {
            if(members[i] != msg.sender) {
                balances[members[i]] = msg.value / 2;
            }

        }
    }

    function showGroupBalances(address forAddress) constant returns (address[3] members, uint[3] memberBalances) {
        members = splitGroups[forAddress].groupMembers;
        for(uint8 i = 0; i < members.length; i++) {
            memberBalances[i] = balances[members[i]];
        }
        return (members, memberBalances);
    }

    function destroy() onlyOwner {
        suicide(owner);
    }

    function() payable {
        if(splitGroups[msg.sender].isSet) {
            split();
        }
    }
}
