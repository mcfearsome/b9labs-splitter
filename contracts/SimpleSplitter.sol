pragma solidity ^0.4.11;

import "./mortal.sol";

contract SimpleSplitter is mortal {
  mapping(address => uint) balances;

  function split(address receiverOne, address receiverTwo) payable {
    require(msg.value > 0);
    require(receiverOne != receiverTwo);
    require(receiverOne != 0x0 && receiverTwo != 0x0);
    require(receiverOne != msg.sender && receiverTwo != msg.sender);

    uint half = msg.value / 2;
    assert(half > 0);

    uint8 remainder = uint8(msg.value % half);
    balances[receiverOne] += half;
    balances[receiverTwo] += half;
    if(remainder > 0) {
      // What to do with this is the question?
      // It's not fair to give it to either of the receivers in my eyes
      // So I will store it in the balance of the sender
      // They can either withdraw it, or if they receive a split they will get it
      balances[msg.sender] += uint256(remainder);
    }

    assert(_withdraw(receiverOne));
    assert(_withdraw(receiverTwo));
  }

  function withdraw() {
    assert(_withdraw(msg.sender));
  }

  function _withdraw(address to) internal returns(bool) {
    uint amount = balances[to];
    require(amount != 0);
    require(this.balance >= amount);
    balances[to] = 0;
    return to.send(amount);
  }

  function() { }
}
