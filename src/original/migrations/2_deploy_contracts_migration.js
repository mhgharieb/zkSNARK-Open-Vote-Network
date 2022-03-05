const { MerkleTree } = require('../helper/merkletree.js')
var Migrations = artifacts.require("Migrations.sol");
const eVote = artifacts.require("eVote.sol");
const verifierMerkleTree = artifacts.require("verifierMerkleTree");
const verifierZKSNARK = artifacts.require("verifierZKSNARK");


module.exports = function(deployer, network, accounts) {
    let usersMerkleTree = new MerkleTree(accounts.slice(1,accounts.length-1));
    deployer.deploy(Migrations);
    deployer.deploy(verifierMerkleTree);
    deployer.deploy(verifierZKSNARK).then(function() {
        return deployer.deploy(eVote, verifierMerkleTree.address, verifierZKSNARK.address, usersMerkleTree.getHexRoot(),300,300,300,{from:accounts[0], value:web3.utils.toWei("1","ether")})
    });
    
    
};
