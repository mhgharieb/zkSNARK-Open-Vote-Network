pragma circom 2.0.0;
include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/mux1.circom";
include "../Utils/Utils.circom";


template split(n){
    signal input elements[n][2];
    signal input Idx;
    signal output elementsBeforeIdx[n][2];
    signal output elementsAfterIdx[n][2];

    component muxBefore[n];
    component iLessThanIdx[n];
    component muxAfter[n];
    component iGreaterThanIdx[n];

    var log2N = log2(n);
    for (var i = 0; i<n; i++){
        muxBefore[i] = MultiMux1(2);
        iLessThanIdx[i] = LessThan(log2N);
        iLessThanIdx[i].in[0] <== i;
        iLessThanIdx[i].in[1] <== Idx;
        muxBefore[i].s <== iLessThanIdx[i].out;
        muxBefore[i].c[0][0] <== 0;
        muxBefore[i].c[1][0] <== 1;
        muxBefore[i].c[0][1] <== elements[i][0];
        muxBefore[i].c[1][1] <== elements[i][1];
        elementsBeforeIdx[i][0] <== muxBefore[i].out[0];
        elementsBeforeIdx[i][1] <== muxBefore[i].out[1];

        muxAfter[i] = MultiMux1(2);
        iGreaterThanIdx[i] = GreaterThan(log2N);
        iGreaterThanIdx[i].in[0] <== i;
        iGreaterThanIdx[i].in[1] <== Idx;
        muxAfter[i].s <== iGreaterThanIdx[i].out;
        muxAfter[i].c[0][0] <== 0;
        muxAfter[i].c[1][0] <== 1;
        muxAfter[i].c[0][1] <== elements[i][0];
        muxAfter[i].c[1][1] <== elements[i][1];
        elementsAfterIdx[i][0] <== muxAfter[i].out[0];
        elementsAfterIdx[i][1] <== muxAfter[i].out[1];
    }   
} 




template encryptedVoteGen(n){
    /*
    // Generate the encrypted vote for a voter i
    // let N be the number of votes and  the neutral element be the point O = (0, 1)
    */
    signal input VotingKeysX[n];
    signal input VotingKeysY[n];
    signal input Idx;
    // a secret key xi
    signal input xi;
    // a vote vi \in {0, 1}
    signal input vote;

    // VotingKeysBeforei = [voting keys from 0 to i-1 then append (N-i-1) neutral elements] = [xG0, xG1, ..., xGi-1, O, O, O, ..., O], |VotingKeysBeforei| = N-1 = n
    signal VotingKeysBeforeIdx[n][2];
    // VotingKeysAfteri = [append (i) neutral elements then voting keys from i+1 to N-1] = [O, O, O, ..., O, xGi+1, xGi+2, ..., xGN-1], |VotingKeysAfteri| = N-1 = n
    signal VotingKeysAfterIdx[n][2];

    
    
    // Yb = xG0 + xG1 + ... + xGi-1
    signal VotingKeysBeforeIdxSum[2];
    // Ya = xGi+1 + xGi+2 + ... + xGN-1
    signal VotingKeysAfterIdxSum[2];

    // blinding key Yi = Yb - Ya
    signal Yi[2];

    // xi * Yi
    signal xYi[2];

    // Encrpyted vote (c) = xi * Yi + vi * BASE
    signal output encryptedVote[2];

    //Assert that the vote is binary
    (vote) * (vote - 1) === 0;

    // Check that the each pair of X and Y is on BabyJub curve
    component checkPoints = BabyCheckArray(n);
    
    for(var i=0; i<n;i++){
        checkPoints.X[i] <== VotingKeysX[i];
        checkPoints.Y[i] <== VotingKeysY[i];
    }

    // Check that each X has positive sign => X = min(X, p-X) => X < p/2
    component BabySignCalX = BabySignCal(n);
    for(var i=0;i<n;i++){
        BabySignCalX.in[i] <== VotingKeysX[i];
    }
    for(var i=0;i<n;i++){
        BabySignCalX.sign[i] === 0;
    }


    // Split Yi to Yl and Yg
    component Spliter;
    Spliter = split(n);
    Spliter.Idx <== Idx;
    for (var i=0; i<n; i++){
        Spliter.elements[i][0] <== VotingKeysX[i];
        Spliter.elements[i][1] <== VotingKeysY[i];
    }
    for (var i=0; i<n; i++){
        VotingKeysBeforeIdx[i][0] <== Spliter.elementsBeforeIdx[i][0];
        VotingKeysBeforeIdx[i][1] <== Spliter.elementsBeforeIdx[i][1];
        VotingKeysAfterIdx[i][0] <== Spliter.elementsAfterIdx[i][0];
        VotingKeysAfterIdx[i][1] <== Spliter.elementsAfterIdx[i][1];
    }


    // Calculate Yl and Yg
    component sumBeforeIdx  = ecBabyjubArraySum(n);
    component sumAfterIdx  = ecBabyjubArraySum(n);
    for(var i=0; i<n; i++){
        sumBeforeIdx.points[i][0] <== VotingKeysBeforeIdx[i][0];
        sumBeforeIdx.points[i][1] <== VotingKeysBeforeIdx[i][1];
        sumAfterIdx.points[i][0] <== VotingKeysAfterIdx[i][0];
        sumAfterIdx.points[i][1] <== VotingKeysAfterIdx[i][1];
        

    }
    
    VotingKeysBeforeIdxSum[0] <== sumBeforeIdx._output[0];
    VotingKeysBeforeIdxSum[1] <== sumBeforeIdx._output[1];

    VotingKeysAfterIdxSum[0] <== sumAfterIdx._output[0];
    VotingKeysAfterIdxSum[1] <== sumAfterIdx._output[1];


    // Calculate Yi = Yl - Yg = Yl + (-Yg) = (Ylx, Yly) + (-Ygx, Ygy) = (Ylx, Yly) + (p -Ygx, Ygy)
    component Adder1 = BabyAdd();
    var p = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    Adder1.x1 <== VotingKeysBeforeIdxSum[0];
    Adder1.y1 <== VotingKeysBeforeIdxSum[1];
    Adder1.x2 <== p - VotingKeysAfterIdxSum[0];
    Adder1.y2 <== VotingKeysAfterIdxSum[1];
    Yi[0] <== Adder1.xout;
    Yi[1] <== Adder1.yout;
    

    // Calculate xi * Yi
    component Multiplier = scalarMulPoint();
    Multiplier.e <== xi;
    Multiplier.p[0] <== Yi[0];
    Multiplier.p[1] <== Yi[1];

    xYi[0] <== Multiplier.out[0];
    xYi[1] <== Multiplier.out[1];

    // Calcaulate the encrpyed vote(c)
    // if vi = 0 => c = xYi + the neutral element (O)
    // of vi = 1 => c = xYi + BASE8
    component Multiplexer = MultiMux1(2);
    var BASE8[2] = [
        5299619240641551281634865583518297030282874472190772894086521144482721001553,
        16950150798460657717958625567821834550301663161624707787222815936182638968203
    ];
    Multiplexer.c[0][0] <== 0;
    Multiplexer.c[1][0] <== 1;
    Multiplexer.c[0][1] <== BASE8[0];
    Multiplexer.c[1][1] <== BASE8[1];
    Multiplexer.s <== vote;
    
    component Adder2 = BabyAdd();
    Adder2.x1 <== xYi[0];
    Adder2.y1 <== xYi[1];
    Adder2.x2 <== Multiplexer.out[0];
    Adder2.y2 <== Multiplexer.out[1];

    encryptedVote[0] <== Adder2.xout;
    encryptedVote[1] <== Adder2.yout;
    
}


component main{public [VotingKeysY, Idx]} = encryptedVoteGen(__NVOTERS__);