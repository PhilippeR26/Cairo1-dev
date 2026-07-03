#!/usr/bin/env bash
# End-to-end TIMELOCK sub-account demo on a local Starknet Devnet.
# Shows the two-phase flow: request (arm) -> advance time -> request again (execute).
# Prereq: in another terminal, run:  starknet-devnet --seed 0
set -euo pipefail
cd "$(dirname "$0")/.."   # -> package root (src/cairo2190/sub-account)

RPC="http://127.0.0.1:5050"
ACCT_FILE="accounts.json"
RECIPIENT="0x2222"
DELAY=60       # seconds the request must age before it can execute
WINDOW=300     # seconds the request stays executable after the delay
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
ADAPTER_HASH=$(declare_hash TimelockTransferAdapter)

echo "==> Deploying contracts"
TOKEN=$(deploy_addr "$ERC20_HASH")
SUB=$(deploy_addr "$SUB_HASH" "$ADDR")
# timelock adapter constructor: (owner, delay: u64, window: u64) -> one felt each
ADAPTER=$(deploy_addr "$ADAPTER_HASH" "$ADDR" "$DELAY" "$WINDOW")
echo "TOKEN=$TOKEN  SUB=$SUB  ADAPTER=$ADAPTER  (delay=${DELAY}s window=${WINDOW}s)"

echo "==> Setup: mint -> sub, whitelist adapter, grant allowance"
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$TOKEN" --function mint --calldata "$SUB" 1000 0
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$SUB" --function set_adapter --calldata "$ADAPTER" 1
"${SNCAST[@]}" invoke --url "$RPC/rpc" \
  --contract-address "$SUB" --function approve_token --calldata "$TOKEN" "$ADAPTER" 500 0

# execute(Call{to, selector, calldata}) for request_transfer(token, recipient, amount)
# inner Serde: to, selector, span_len(=4), token, recipient, amount_low, amount_high
SEL=$(starkli selector request_transfer)
INNER=(--contract-address "$SUB" --function execute --calldata "$ADAPTER" "$SEL" 4 "$TOKEN" "$RECIPIENT" "$AMOUNT" 0)

echo "==> Phase 1: request the transfer (arms it, moves nothing)"
"${SNCAST[@]}" invoke --url "$RPC/rpc" "${INNER[@]}"
echo -n "recipient balance right after request (expect [0x0, 0x0]): "
"${SNCAST[@]}" call --url "$RPC/rpc" --contract-address "$TOKEN" --function balance_of --calldata "$RECIPIENT"

echo "==> Trying to execute too early (before the delay) — expected to be REJECTED"
if "${SNCAST[@]}" invoke --url "$RPC/rpc" "${INNER[@]}" >/dev/null 2>&1; then
  echo "   !! UNEXPECTED: the transfer went through before the delay"
else
  echo "   ok: rejected (TOO_EARLY) — the timelock is holding"
fi

echo "==> Advancing Devnet time by $((DELAY + 60))s"
rpc devnet_increaseTime "{\"time\": $((DELAY + 60))}" >/dev/null

echo "==> Phase 2: re-request the SAME transfer (now within the window -> executes)"
"${SNCAST[@]}" invoke --url "$RPC/rpc" "${INNER[@]}"

echo "==> Verifying balances"
echo -n "recipient balance: "
"${SNCAST[@]}" call --url "$RPC/rpc" --contract-address "$TOKEN" --function balance_of --calldata "$RECIPIENT"
echo -n "sub-account balance: "
"${SNCAST[@]}" call --url "$RPC/rpc" --contract-address "$TOKEN" --function balance_of --calldata "$SUB"
echo "==> Done. Expected: recipient = [0xc8, 0x0] (200), sub = [0x320, 0x0] (800)"
