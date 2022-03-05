#!/bin/bash
set -e


powersOfTau="powersOfTau28_hez_final_18.ptau"


# colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`

# function for circuit compilation and key Gen
function circuitCompileGenKey(){
   citcuitName="$1"
   verifierKeyName="$2"
   circuitLoc="$3"
   echo "${GREEN}Compiling $citcuitName circuit${NC}" >&2
   compile_start=$(date +%s%N)
   if ! circom ../circuits/"$circuitLoc"/"$citcuitName".circom --r1cs --wasm >&2  ||
      ! [[ -s ./"$citcuitName"_js/"$citcuitName".wasm ]]
   then
      echo "${RED}$citcuitName compilation failed${NC}" >&2
      exit 1
   else
      echo "${GREEN}$citcuitName compilation succeeded${NC}" >&2
   fi
   compile_end=$(date +%s%N)

   echo "${GREEN}Generating proving key for $citcuitName circuit${NC}" >&2
   keyGen_start=$(date +%s%N)
   $snarkjs groth16 setup "$citcuitName".r1cs potfinal.ptau "$citcuitName"000.zkey >&2
   if [[ ! -s "$citcuitName"000.zkey ]]; then
      echo "${RED}Generating proving key for $citcuitName circuit failed${NC}" >&2
      echo "${RED}May need to update \$powersOfTau, for more information, https://github.com/iden3/snarkjs#7-prepare-phase-2${NC}" >&2
      exit -1
   fi
   $snarkjs zkey contribute "$citcuitName"000.zkey "$citcuitName"001.zkey --name="1st Contributor Name" -v -e="more random text" >&2
   $snarkjs zkey contribute "$citcuitName"001.zkey "$citcuitName"002.zkey --name="Second contribution Name" -v -e="Another random entropy" >&2
   $snarkjs zkey beacon "$citcuitName"002.zkey "$citcuitName"Final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2" >&2
   keyGen_end=$(date +%s%N)
   $snarkjs zkey export verificationkey "$citcuitName"Final.zkey "$verifierKeyName".json
   echo "${GREEN}Generating proving key for $citcuitName circuit completed${NC}" >&2

   #statistics
   Nconstraints=`$snarkjs r1cs info "$citcuitName".r1cs|grep "Constraints"|cut -d ":" -f 3`
   compileTime=$(((compile_end - compile_start)/1000000))
   keyGenTime=$(((keyGen_end - keyGen_start)/1000000))
   provingKeySize=`stat -c%s "$citcuitName"Final.zkey`
   
   #delete temp keys
   rm "$citcuitName"000.zkey
   rm "$citcuitName"001.zkey
   rm "$citcuitName"002.zkey
   
   #return statistics
   echo "$Nconstraints $compileTime $keyGenTime $provingKeySize"

}

# function for printing statistics of a cuircit
function printStatistics(){
   citcuitName="$1"
   statistics=($2)

   echo """

   Statistics of ${GREEN}$citcuitName${NC} circuit:
   number of constraints = ${GREEN}${statistics[0]}${NC}, 
   compilation time      = ${GREEN}${statistics[1]}${NC} ms, 
   proof generation time = ${GREEN}${statistics[2]}${NC} ms,
   proving Key Size      = ${GREEN}${statistics[3]}${NC} Bytes
   
   """  >&2
}

# Main()

useMessage="Useage: ./setup.sh -d ${GREEN}[original|sha256|progressiveSha256|progressivePoseidon]${NC} -n ${GREEN}[NUMBER_of_VOTERS]${NC}"

# Parsing arguments
while getopts "hd:n:" opt
do
   case "$opt" in
      d) 
         designOpt="$OPTARG";
         possibleDesignOpt=('original' 'sha256' 'progressiveSha256' 'progressivePoseidon');
         if [[ ! " ${possibleDesignOpt[*]} " =~ " ${designOpt} " ]]; then
            echo $useMessage;
            exit 1
         fi
      ;;
      n)
         nVotersOpt="$OPTARG";
         if [[ $nVotersOpt -le "0" ]]; then
            echo $useMessage;
            exit 1
         fi
      ;;
      h) 
         echo $useMessage;
         exit 0
      ;;
      :)
         echo $useMessage;
         exit 1
      ;;
      *)
         echo $useMessage;
         exit 1
      ;;
   esac
done

design="${designOpt:-original}"
nVoters="${nVotersOpt:-3}"
srcDir=../src/"$design"
snarkjs=../node_modules/.bin/snarkjs

# clear previous run
rm -rf ./PublicKeyGen_js
rm -rf ./encryptedVoteGen_js
rm -rf ./tallying_js
rm -f ./*.zkey
rm -f ./*.r1cs
rm -f ./*.json
rm -rf ../circuits
rm -rf ../contracts
rm -rf ../test

mkdir -p ../circuits
mkdir -p ../contracts
mkdir -p ../test


echo "Used Design: ${GREEN}$design${NC}, NUMBER_of_VOTERS = ${GREEN}$nVotersOpt${NC}"

# check dependencies
if [[ ! -d "../node_modules" ]]; then
   echo "${GREEN}Install dependencies packages${NC}"
    cd ../
    npm i
    cd build
fi

# check powersoftau
if [[ ! -f "potfinal.ptau" ]]; then
   #$snarkjs powersoftau new bn128 18 pot0.ptau -v
   #$snarkjs powersoftau contribute pot0.ptau pot1.ptau --name="First contribution" -v -e="random text"
   #$snarkjs powersoftau contribute pot1.ptau pot2.ptau --name="Second contribution" -v -e="some random text"
   #$snarkjs powersoftau beacon pot2.ptau potbeacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"
   #$snarkjs powersoftau prepare phase2 potbeacon.ptau potfinal.ptau -v
   echo "${GREEN}Downloading powersOfTau${NC}"
   curl https://hermez.s3-eu-west-1.amazonaws.com/$powersOfTau -o "potfinal.ptau"
else
   echo "${GREEN}powersOfTau exists, skipping download${NC}"
fi

# increase the heap size for node
if [[ "$design" = "progressiveSha256" || "$design" = "sha256" ]]; then 
   export NODE_OPTIONS=--max-old-space-size=32768
fi

# compile and key Gen
cp -r $srcDir/circuits/* ../circuits/

PublicKeyGenStatistics=$(circuitCompileGenKey "PublicKeyGen" "verifier_PublicKey" "voter")

sed -i "s/__NVOTERS__/$nVoters/g" ../circuits/voter/encryptedVoteGen.circom
encryptedVoteGenStatistics=$(circuitCompileGenKey "encryptedVoteGen" "verifier_EncrpytedVote" "voter")


sed -i "s/__NVOTERS__/$nVoters/g" ../circuits/administrator/tallying.circom
tallyingStatistics=$(circuitCompileGenKey "tallying" "verifier_tallying" "administrator")


# modify contracts and test script
echo "${GREEN}Modifying contracts${NC}"

cp -r "$srcDir"/contracts/* ../contracts/
sed -i "s/__NVOTERS__/$nVoters/g" ../contracts/eVote.sol

if [[ "$design" = "original" || "$design" = "sha256" ]]; then
   (( sign_size=(nVoters+252)/253 )); # ceil(nVoters/253)
   XSign=`python3 -c "print([0] * $sign_size)"`
   sed -i "s/__XSIGN__/$XSign/g" ../contracts/eVote.sol
fi

echo "${GREEN}Modifying contracts completed${NC}"

cp -r $srcDir/test/* ../test/
sed -i "s/__NVOTERS__/$nVoters/g" ../test/completeTest.js
cp -r $srcDir/migrations/* ../migrations/
cp -r $srcDir/helper/* ../helper/


#print statistics
printStatistics "PublicKeyGen" "$PublicKeyGenStatistics"
printStatistics "encryptedVoteGen" "$encryptedVoteGenStatistics"
printStatistics "tallying" "$tallyingStatistics"



# print how to run test
echo """

To test, run the following commands in two different terminals:
terminal 1:
            ${GREEN}ganache-cli -l 30e6 -a $((nVoters+2))${NC} 
terminal 2:
            ${GREEN}cd ../test
            ${GREEN}truffle test

${NC}"""



