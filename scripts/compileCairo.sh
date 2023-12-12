cd cairo
cargo run --release --bin starknet-compile -- --single-file --allowed-libfuncs-list-file ../scripts/lib_funcs.json ../src/hello/hello.cairo ../out/hello/hello.sierra.json