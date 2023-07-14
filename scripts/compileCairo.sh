cd cairo
cargo run --bin starknet-compile -- --allowed-libfuncs-list-file ../scripts/lib_funcs.json ../src/hello/hello.cairo ../out/hello/hello.sierra.json