pragma circom 2.0.0;
include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../Utils/Utils.circom";


template PublicKeyGen(){
    signal input privateKey;
    signal output publicKey[2];

    component publicKeyGen = BabyPbk();
    publicKeyGen.in <== privateKey;
    publicKey[0] <== publicKeyGen.Ax;
    publicKey[1] <== publicKeyGen.Ay;
    
    component BabySignCalX = BabySignCal(1);
    BabySignCalX.in[0] <== publicKey[0];
    BabySignCalX.sign[0] === 0;


}


component main = PublicKeyGen();