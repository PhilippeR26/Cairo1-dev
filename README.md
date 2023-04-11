# Cairo1-dev
 Environment for Starknet Cairo1 smart-contracts creation.

## Installation :

To install the JS dependencies :
```bash
npm i
```

Cairo 1 has to be installed in `./cairo`, from Starkware repo, branch `v1.0.0-alpha.6` [here](https://github.com/starkware-libs/cairo/tree/v1.0.0-alpha.6).  
Do not forget To install VSCode extension for Cairo 1 : [here](https://github.com/starkware-libs/cairo/tree/v1.0.0-alpha.6/vscode-cairo).

## New project :

Create a new directory in `./src`.  
In this directory, create your .cairo files.

## Compile :

First, compile the .cairo file to .sierra :
```bash
cd cairo
cargo run --bin starknet-compile -- ../src/merkle/merkle_verify_c1.cairo ../out/merkle/merkle_starknet.sierra
```

Then, compile the sierra file to .casm :
```bash
cargo run --bin starknet-sierra-compile -- ../out/merkle/merkle_starknet.sierra ../out/merkle/merkle_starknet.casm
```

## Test :

🚧 Waiting Starknet plugin for Hardhat to be updated for Cairo 1 🚧
 
## Deploy in your DAPP :

Copy the .sierra/.casm files to your front-end project. Use [Starknet.js](https://www.starknetjs.com/) to interact with the Starknet blockchain.
