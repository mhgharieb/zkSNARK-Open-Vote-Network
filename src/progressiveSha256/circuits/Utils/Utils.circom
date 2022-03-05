pragma circom 2.0.0;
include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/escalarmulany.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/switcher.circom";
include "../../node_modules/circomlib/circuits/compconstant.circom";
include "../../node_modules/circomlib/circuits/sha256/sha256.circom";


template ecBabyjubArraySum(n){

    signal input points[n][2];
    signal output _output[2];
    
    component adder[n-1];

    adder[0] = BabyAdd();
    adder[0].x1 <== points[0][0];
    adder[0].y1 <== points[0][1];
    adder[0].x2 <== points[1][0];
    adder[0].y2 <== points[1][1];

    for(var i = 1; i < n-1; i++){
        adder[i] = BabyAdd();
        adder[i].x1 <== adder[i-1].xout;
        adder[i].y1 <== adder[i-1].yout;
        adder[i].x2 <== points[i+1][0];
        adder[i].y2 <== points[i+1][1];
    }

    _output[0] <== adder[n-2].xout;
    _output[1] <== adder[n-2].yout;
}






template scalarMulPoint() {
    signal input e; 
    signal input p[2];
    signal output out[2];

    component eBits = Num2Bits(253);
    component multiplier = EscalarMulAny(253);

    eBits.in <== e;
    
    multiplier.p[0] <== p[0];
    multiplier.p[1] <== p[1];

    for (var i=0; i<253; i++) {
        multiplier.e[i] <== eBits.out[i];
    }
    out[0] <== multiplier.out[0];
    out[1] <== multiplier.out[1];
}



function fBabyAdd(x1,y1,x2,y2) {
    var a = 168700;
    var d = 168696;

    var res[2];
    res[0] = (x1*y2 + y1*x2) / (1 + d*x1*x2*y1*y2);
    res[1] = (y1*y2 - a*x1*x2) / (1 - d*x1*x2*y1*y2);
    return res;
}


template ecIsEqual(){
    signal input in1[2];
    signal input in2[2];
    signal output out;

    component checkx = IsEqual();
    component checky = IsEqual();
    checkx.in[0] <== in1[0];
    checkx.in[1] <== in2[0];
    checky.in[0] <== in1[1];
    checky.in[1] <== in2[1];
    out <== checkx.out * checky.out;

}


template ecSwitcher(){
    signal input L[2];
    signal input R[2];
    signal input sel;
    signal output outL[2];
    signal output outR[2];

    component switcherx = Switcher();
    component switchery = Switcher();
    switcherx.L <== L[0];
    switcherx.R <== R[0];
    outL[0] <== switcherx.outL; 
    outR[0] <== switcherx.outR; 

    switchery.L <== L[1];
    switchery.R <== R[1];
    outL[1] <== switchery.outL; 
    outR[1] <== switchery.outR; 



}




function log2(a) {
    // roughly log2, return r such that a <= 2^r
    assert(a > 0);
    var n = 1;
    var r = 1;
    while (n<a) {
        r++;
        n *= 2;
    }
    return r;
}


template BabyCheckArray(n){
    signal input X[n];
    signal input Y[n];

    component check[n];
    for(var i=0; i<n;i++){
        check[i] = BabyCheck();
        check[i].x <== X[i];
        check[i].y <== Y[i];
    }
}


template BabySignCal(n){
    signal input in[n];
    signal output sign[n];

    component signCalc[n];
    component n2b[n];
    for(var i=0;i<n;i++){
        signCalc[i] = CompConstant(10944121435919637611123202872628637544274182200208017171849102093287904247808);
        n2b[i] = Num2Bits(254);
        n2b[i].in <== in[i];
        for (var j=0; j<254; j++) {
            signCalc[i].in[j] <== n2b[i].out[j];
        }
        sign[i] <== signCalc[i].out;
    }
}


template HashInputs(size){

    signal input in[size];
    signal output out;

    component n2b[size];
    component sha256 = Sha256(size*256);

    for(var i=0; i<size; i++){
        n2b[i] = Num2Bits(256);
        n2b[i].in <== in[i];
        for(var j=0; j<256; j++)
            sha256.in[i*256+255-j] <== n2b[i].out[j];
    }
    
    component b2n = Bits2Num(256);
    for (var i = 0; i < 256; i++) {
        b2n.in[i] <== sha256.out[255-i];
    }
    out <== b2n.out;
}


template HashInputs2(size){

    signal input in[size];
    signal output out;

    component hashInputs_2[size];
    hashInputs_2[0] = HashInputs(2);
    hashInputs_2[0].in[0] <== 0;
    hashInputs_2[0].in[1] <== in[0];
    
    for (var i=1; i<size;i++){
        hashInputs_2[i] = HashInputs(2);
        hashInputs_2[i].in[0] <== hashInputs_2[i-1].out;
        hashInputs_2[i].in[1] <== in[i];
    }

    out <== hashInputs_2[size-1].out;
}

template HashInputs3(size){

    signal input in[size][2];
    signal output out;

    component hashInputs_3[size];
    hashInputs_3[0] = HashInputs(3);
    hashInputs_3[0].in[0] <== 0;
    hashInputs_3[0].in[1] <== in[0][0];
    hashInputs_3[0].in[2] <== in[0][1];
    
    for (var i=1; i<size;i++){
        hashInputs_3[i] = HashInputs(3);
        hashInputs_3[i].in[0] <== hashInputs_3[i-1].out;
        hashInputs_3[i].in[1] <== in[i][0];
        hashInputs_3[i].in[2] <== in[i][1];
    }

    out <== hashInputs_3[size-1].out;
}





// component main{public [points]} = ecBabyjubArrayAdd(4);
