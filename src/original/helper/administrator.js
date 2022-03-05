const { FullProve } = require('./snarkjsHelper')
const tallying_wasm = "../build/tallying_js/tallying.wasm";
const tallying_zkey = "../build/tallyingFinal.zkey";
const tallying_wtns_cal = '../build/tallying_js/witness_calculator.js';


async function tallying(encryptedVotes){
    let encryptedVotesX = [];
    let encryptedVotesY = [];
    for (i=0; i<encryptedVotes.length; i++){
        encryptedVotesX.push(encryptedVotes[i][0])
        encryptedVotesY.push(encryptedVotes[i][1])
    }    
    const {genWitnessTime, genProofTime, proof, publicSignals} = await FullProve(
        {"encryptedVotesX": encryptedVotesX,
         "encryptedVotesY": encryptedVotesY},
        tallying_wasm,
        tallying_zkey,
        tallying_wtns_cal
    );
    console.log(`Tallying_genWitnessTime = ${genWitnessTime} ms, Tallying_genProofTime = ${genProofTime} ms`)
    const tallyingResult = publicSignals[0];
    const tallyingProof = {
        a: [proof.pi_a[0], proof.pi_a[1]],
        b: [
            [proof.pi_b[0][1], proof.pi_b[0][0]],
            [proof.pi_b[1][1], proof.pi_b[1][0]],
          ],
        c: [proof.pi_c[0], proof.pi_c[1]]
    } 
    
    return { tallyingProof, tallyingResult }
}

module.exports = {
    tallying
}
