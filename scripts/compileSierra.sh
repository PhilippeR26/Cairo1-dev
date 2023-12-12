cargo run --release --bin starknet-sierra-compile -- ../out/hello/hello.sierra.json  ../out/hello/hello.casm.json --allowed-libfuncs-list-file ../scripts/lib_funcs.json

# launch devnet with
# starknet-devnet --seed 0 --verbose --compiler-args '--allowed-libfuncs-list-file /D/Cairo1-dev/scripts/lib_funcs.json --add-pythonic-hints' 2> /dev/null &

