# go to Cairo v2.2.0 directory
cargo run --release --bin starknet-compile -- /home/edmond/Documents/starknet/OpenZeppelin/cairo-contracts/src/ ../out/cairo220/OpenZeppelin/erc20OZ070.sierra.json --contract-path openzeppelin::token::erc20::erc20::ERC20
cargo run --release --bin starknet-sierra-compile --  ../out/cairo220/OpenZeppelin/erc20OZ070.sierra.json ../out/cairo220/OpenZeppelin/erc20OZ070.casm.json
