var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', accounts => {
  var contract;

  it("should create a split group", done => {
    var instance;
    var groupIndex;
    var groupCollection = [];


    Splitter.deployed()
      .then(_instance => {
        instance = _instance;
        return instance.createSplitGroup(accounts.slice(1, 3), { from: accounts[0] });
      })
      .then(txInfo => {
        return instance.splitGroupsByAddress.call(accounts[0]);
      })
      .then(_groupIndex => {
        groupIndex = _groupIndex;
        assert.equal(groupIndex, 1, 'there should be only 1 group');
        return instance.splitGroups(groupIndex, 0);
      })
      .then(groupAddress => {
        groupCollection.push(groupAddress);
        return instance.splitGroups(groupIndex, 1);
      })
      .then(groupAddress => {
        groupCollection.push(groupAddress);
        return instance.splitGroups(groupIndex, 2);
      })
      .then(groupAddress => {
        groupCollection.push(groupAddress);
        var matchingAccounts = accounts.slice(1,3);
        matchingAccounts.push(accounts[0]);
        assert.deepEqual(groupCollection, matchingAccounts, 'group should contain the first 3 accounts');
        groupCollection = [];
        groupIndex = null;
        return instance.createSplitGroup(accounts.slice(3,5), { from: accounts[1] });
      })
      .catch(e => {
        return instance.splitGroupsByAddress.call(accounts[3]);
      })
      .then(groupIndex => {
        assert.equal(groupIndex, 0, 'a new group shouldn\'t of been created');
        return instance.createSplitGroup(accounts.slice(1, 2), { from: accounts[0] });
      })
      .catch(e => {
        return instance.splitGroupsByAddress.call(accounts[3]);
      })
      .then(groupIndex => {
        assert.equal(groupIndex, 1, 'group index should remain the same');
        return instance.createSplitGroup(accounts.slice(3, 5), { from: accounts[3] });
      })
      .catch(e => {
        return instance.splitGroupsByAddress.call(accounts[3]);
      })
      .then(groupIndex => {
        assert.equal(groupIndex, 0, 'group creator cannot be in group twice');
        return instance.createSplitGroup([accounts[4], accounts[4]], { from: accounts[0] });
      })
      .catch((e) => {
        return instance.splitGroupsByAddress.call(accounts[4]);
      })
      .then(groupIndex => {
        assert.equal(groupIndex, 0, 'group member cannot be in group twice');
        done();
      })
      .catch(done);
  });

  it('should properly split wei sent', done => {
    var instance;

    Splitter.new()
      .then(_instance => {
        instance = _instance;
        return instance.createSplitGroup(accounts.slice(1, 3), { from: accounts[0] });
      })
      .then(txInfo => {
        console.log('group created')
        return instance.sendTransaction({
          from: web3.eth.accounts[1],
          value: 3
        });
      })
      .then(txInfo => {
        return instance.showGroupBalances(web3.eth.accounts[2]);
      })
      .then(returnValue => {
        assert.equal(returnValue[1][0], 1, 'each account should have 1 wei');
        assert.equal(returnValue[1][1], 1, 'each account should have 1 wei');
        assert.equal(returnValue[1][2], 1, 'each account should have 1 wei');
        done();
      })
  })
});





//
//
//
// var MetaCoin = artifacts.require("./MetaCoin.sol");
//
// contract('MetaCoin', function(accounts) {
//   it("should put 10000 MetaCoin in the first account", function() {
//     return MetaCoin.deployed().then(function(instance) {
//       return instance.getBalance.call(accounts[0]);
//     }).then(function(balance) {
//       assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
//     });
//   });
//   it("should call a function that depends on a linked library", function() {
//     var meta;
//     var metaCoinBalance;
//     var metaCoinEthBalance;
//
//     return MetaCoin.deployed().then(function(instance) {
//       meta = instance;
//       return meta.getBalance.call(accounts[0]);
//     }).then(function(outCoinBalance) {
//       metaCoinBalance = outCoinBalance.toNumber();
//       return meta.getBalanceInEth.call(accounts[0]);
//     }).then(function(outCoinBalanceEth) {
//       metaCoinEthBalance = outCoinBalanceEth.toNumber();
//     }).then(function() {
//       assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, "Library function returned unexpected function, linkage may be broken");
//     });
//   });
//   it("should send coin correctly", function() {
//     var meta;
//
//     // Get initial balances of first and second account.
//     var account_one = accounts[0];
//     var account_two = accounts[1];
//
//     var account_one_starting_balance;
//     var account_two_starting_balance;
//     var account_one_ending_balance;
//     var account_two_ending_balance;
//
//     var amount = 10;
//
//     return MetaCoin.deployed().then(function(instance) {
//       meta = instance;
//       return meta.getBalance.call(account_one);
//     }).then(function(balance) {
//       account_one_starting_balance = balance.toNumber();
//       return meta.getBalance.call(account_two);
//     }).then(function(balance) {
//       account_two_starting_balance = balance.toNumber();
//       return meta.sendCoin(account_two, amount, {from: account_one});
//     }).then(function() {
//       return meta.getBalance.call(account_one);
//     }).then(function(balance) {
//       account_one_ending_balance = balance.toNumber();
//       return meta.getBalance.call(account_two);
//     }).then(function(balance) {
//       account_two_ending_balance = balance.toNumber();
//
//       assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
//       assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
//     });
//   });
// });
