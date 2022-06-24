const { MerkleTree } = require('../helper/merkletree.js')
var Migrations = artifacts.require("Migrations.sol");
const eVote = artifacts.require("eVote.sol");
const verifierMerkleTree = artifacts.require("verifierMerkleTree");
const verifierZKSNARK = artifacts.require("verifierZKSNARK");
const poseidonUnit = require("circomlibjs").poseidonContract;

module.exports = async function(deployer, network, accounts) {
    let usersMerkleTree = new MerkleTree(accounts.slice(1,accounts.length-1));
    const poseidonT3contract = new web3.eth.Contract(poseidonUnit.generateABI(2));
    const poseidonT3Instance = await poseidonT3contract.deploy({
            data: poseidonUnit.createCode(2)
            }).send({
            from: accounts[0],
            gas: 30000000
            });
    const poseidonT4contract = new web3.eth.Contract(poseidonUnit.generateABI(3));
    const poseidonT4Instance = await poseidonT4contract.deploy({
            data: poseidonUnit.createCode(3)
            }).send({
            from: accounts[0],
            gas: 30000000
            });
    await deployer.deploy(Migrations);
    await deployer.deploy(verifierMerkleTree);
    await deployer.deploy(verifierZKSNARK).then(function() {
        return deployer.deploy(eVote, verifierMerkleTree.address, verifierZKSNARK.address, poseidonT3Instance.options.address, poseidonT4Instance.options.address, usersMerkleTree.getHexRoot(),300,300,300,{from:accounts[0], value:web3.utils.toWei("1","ether")})
    });
    
    
};
