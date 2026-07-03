#!/usr/bin/env bash
# End-to-end sub-account demo on a local Starknet Devnet (capped-transfer adapter).
# Prereq: in another terminal, run:  starknet-devnet --seed 0
set -euo pipefail
cd "$(dirname "$0")/.."   # -> package root (src/cairo2190/sub-account)

RPC="http://127.0.0.1:5050"
ACCT_FILE="accounts.json"
RECIPIENT="0x1111"
CAP=500
AMOUNT=200

SNCAST=(sncast --accounts-file "$ACCT_FILE" --account devnet0)

rpc() { # rpc <method> <json-params>  -> prints the JSON-RPC response
  curl -s -X POST "$RPC/rpc" -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":$2}"
}

# sncast --json prints several JSON lines (compile progress, the response, then a
# voyager-links notification). Pick the right field with jq; also recover the hash
# from an "already declared" error so re-runs on the same Devnet still work.
declare_hash() { # declare_hash <ContractName>
  "${SNCAST[@]}" --json declare --url "$RPC/rpc" --contract-name "$1" 2>&1 \
    | jq -R 'fromjson? // empty' \
    | jq -rs '(map(select(.class_hash)) | .[0].class_hash)
              // (map(select(.error)) | .[0].error | scan("0x[0-9a-fA-F]+"))
              // empty'
}
deploy_addr() { # deploy_addr <class_hash> [ctor calldata...]
  local ch="$1"; shift
  local args=(); [ "$#" -gt 0 ] && args=(--constructor-calldata "$@")
  "${SNCAST[@]}" --json deploy --url "$RPC/rpc" --class-hash "$ch" "${args[@]}" 2>&1 \
    | jq -R 'fromjson? // empty' \
    | jq -rs 'map(select(.contract_address)) | .[0].contract_address // empty'
}

echo "==> Importing the first pre-deployed Devnet account as 'devnet0'"
# starknet-devnet 0.9.0 (devnet-rs) exposes accounts via the
# devnet_getPredeployedAccounts JSON-RPC method (no REST route).
read -r ADDR PK < <(rpc devnet_getPredeployedAccounts '{}' \
  | jq -r '.result[0] | "\(.address) \(.private_key)"')
rm -f "$ACCT_FILE"
"${SNCAST[@]}" account import --url "$RPC/rpc" \
  --name devnet0 --address "$ADDR" --private-key "$PK" --type oz --silent

echo "==> Declaring contracts"
ERC20_HASH=$(declare_hash MockERC20)
SUB_HASH=$(declare_hash SubAccount)
ADAPTER_HASH=$(declare_hash CappedTransferAdapter)

echo "==> Deploying contracts"
TOKEN=$(deploy_addr "$ERC20_HASH")
SUB=$(deploy_addr "$SUB_HASH" "$ADDR")
# adapter constructor: (token, recipient, cap: u256 -> low, high)
ADAPTER=$(deploy_addr "$ADAPTER_HASH" "$TOKEN" "$RECIPIENT" "$CAP" 0)
echo "TOKEN=$TOKEN  SUB=$SUB  ADAPTER=$ADAPTER"

echo "==> Setup: mint -> sub, whitelist adapter, grant allowance"
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$TOKEN" --function mint --calldata "$SUB" 1000 0
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$SUB" --function set_adapter --calldata "$ADAPTER" 1
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$SUB" --function approve_token --calldata "$TOKEN" "$ADAPTER" "$CAP" 0

echo "==> Execute: relay a capped transfer of $AMOUNT through the adapter"
SEL=$(starkli selector pull_and_transfer)
# execute(Call{to, selector, calldata}) -> Serde: to, selector, span_len(=2), low, high
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$SUB" --function execute \
  --calldata "$ADAPTER" "$SEL" 2 "$AMOUNT" 0

echo "==> Verifying balances"
echo -n "recipient balance: "
"${SNCAST[@]}" call --url "$RPC/rpc" --contract-address "$TOKEN" --function balance_of --calldata "$RECIPIENT"
echo -n "sub-account balance: "
"${SNCAST[@]}" call --url "$RPC/rpc" --contract-address "$TOKEN" --function balance_of --calldata "$SUB"
echo "==> Done. Expected: recipient = [0xc8, 0x0] (200), sub = [0x320, 0x0] (800)"
