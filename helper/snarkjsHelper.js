const snarkjs = require('snarkjs')
const fs = require('fs')

const WITNESS_FILE = '/tmp/witness'

const generateWitness = async (inputs, wasm, witness_calculator) => {
  let t = process.hrtime();
  const wc = require(witness_calculator)
  const buffer = fs.readFileSync(wasm);
  const witnessCalculator = await wc(buffer)
  const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
  fs.writeFileSync(WITNESS_FILE, buff)
  t = process.hrtime(t);
  
  return t[0]*1000 + t[1]/1e6;
}

/*
alternative to snarkjs.groth16.fullProve because it produces an error with circom 2
https://github.com/iden3/snarkjs/issues/107
*/
const FullProve = async (inputSignals, wasm, zkey, witness_calculator) => {
    const genWitnessTime = await generateWitness(inputSignals, wasm, witness_calculator)
    let t = process.hrtime();
    const { proof, publicSignals } = await snarkjs.groth16.prove(zkey, WITNESS_FILE);
    t = process.hrtime(t);
    const genProofTime =  t[0]*1000 + t[1]/1e6;
    return {genWitnessTime, genProofTime, proof, publicSignals}
}

module.exports =  {
    FullProve 

}
