#!/usr/bin/env bash
# End-to-end check of the two OZ Falcon-512 account classes on a local Starknet Devnet:
# declare both classes, deploy one account of each through the UDC with OZ's reference public
# key, then check get_public_key and is_valid_signature with read-only calls.
# Prereq: a running starknet-devnet (tested with 0.11.0); this script never starts one.
# The reference key's secret key is unknown: these accounts cannot send transactions.
#
# Usage: scripts/run_devnet.sh        (env override: RPC, default http://127.0.0.1:5050)
# Exit: 0 when every check passes, 1 otherwise.
set -euo pipefail
cd "$(dirname "$0")/.."   # -> package root (src/cairo2210/OZfalcon512)

RPC="${RPC:-http://127.0.0.1:5050}"
ACCT_FILE="accounts.json"
FIXTURE="tests/falcon_512/fixture.cairo"
PACKAGE="oz_falcon512"
CLASSES=(Falcon512ShakeAccountUpgradeable Falcon512ShakeDirectAccountUpgradeable)
VALIDATED="0x56414c4944" # 'VALID' = starknet::VALIDATED

# Release profile: OZ states that dev-profile Falcon Sierra cannot be lowered to CASM.
SNCAST=(sncast --scarb-profile release --accounts-file "$ACCT_FILE" --account devnet0)

rpc() { # rpc <method> <json-params> -> prints the JSON-RPC response
  curl -s -X POST "$RPC/rpc" -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":$2}"
}

# Numeric literals of one `pub fn <name>()` body of the OZ fixture, one per line.
fixture_felts() {
  sed -n "/^pub fn $1()/,/^}/p" "$FIXTURE" | sed '1d;$d' | sed 's://.*$::' \
    | grep -oE '0x[0-9a-fA-F]+|\b[0-9]+\b'
}

# Lowercase hex without leading zeros, for comparisons (reads stdin, one value per line).
norm() { tr 'A-F' 'a-f' | sed -E 's/^0x0*([0-9a-f])/0x\1/'; }

failures=0
check() { # check <label> <actual> <expected>
  if [ "$2" = "$3" ]; then
    echo "  OK   $1"
  else
    echo "  FAIL $1: got '$2', expected '$3'"
    failures=$((failures + 1))
  fi
}

# sncast --json prints several JSON lines; keep the JSON ones as one array. sncast exits non-zero
# on errors (e.g. "already declared"): callers read the JSON `error` field instead.
sncast_json() {
  { "${SNCAST[@]}" --json "$@" 2>&1 || true; } | jq -R 'fromjson? // empty' | jq -s '.'
}

call_raw() { # call_raw <address> <function> [calldata...] -> raw response felts, space-separated
  local address=$1 function=$2
  shift 2
  local args=()
  [ "$#" -gt 0 ] && args=(--calldata "$@")
  sncast_json call --url "$RPC/rpc" --contract-address "$address" --function "$function" "${args[@]}" \
    | jq -r 'map(select(.response_raw)) | .[0].response_raw // []
             | map(ascii_downcase | sub("^0x0*(?<d>[0-9a-f])"; "0x\(.d)")) | join(" ")'
}

mapfile -t KEY < <(fixture_felts public_key)
mapfile -t SIG < <(fixture_felts signature)
MSG=$(fixture_felts msg)
if [ "${#KEY[@]}" -ne 29 ] || [ "${#SIG[@]}" -ne 60 ] || [ -z "$MSG" ]; then
  echo "Unexpected fixture sizes: key ${#KEY[@]}, signature ${#SIG[@]}, msg '$MSG'" >&2
  exit 1
fi
OTHER_MSG=$(echo "$MSG + 1" | bc)
DIRECT_SIG=("${SIG[@]:0:31}")
EXPECTED_KEY="0x1d $(printf '%s\n' "${KEY[@]}" | norm | tr '\n' ' ')"
EXPECTED_KEY=${EXPECTED_KEY% }

echo "==> Building release artifacts"
build_log=$(mktemp)
trap 'rm -f "$build_log"' EXIT
scarb --release build > "$build_log" 2>&1 || { cat "$build_log"; exit 1; }

echo "==> Importing the first pre-deployed Devnet account as 'devnet0'"
read -r ADDR PK < <(rpc devnet_getPredeployedAccounts '{}' \
  | jq -r '.result[0] | "\(.address) \(.private_key)"')
rm -f "$ACCT_FILE"
"${SNCAST[@]}" account import --url "$RPC/rpc" \
  --name devnet0 --address "$ADDR" --private-key "$PK" --type oz --silent

for class in "${CLASSES[@]}"; do
  echo "==> $class"
  if [ "$class" = "Falcon512ShakeDirectAccountUpgradeable" ]; then
    sig=("${DIRECT_SIG[@]}")
  else
    sig=("${SIG[@]}")
  fi
  expected_hash=$(starkli class-hash "target/release/${PACKAGE}_${class}.contract_class.json" | norm)

  # Declare, or recognise a class declared by a previous run.
  declared=$(sncast_json declare --url "$RPC/rpc" --contract-name "$class")
  class_hash=$(jq -r 'map(select(.class_hash)) | .[0].class_hash // empty' <<<"$declared" | norm)
  if [ -n "$class_hash" ]; then
    tx_hash=$(jq -r 'map(select(.transaction_hash)) | .[0].transaction_hash // empty' <<<"$declared")
    compiled_hash=$(rpc starknet_getTransactionByHash "{\"transaction_hash\":\"$tx_hash\"}" \
      | jq -r '.result.compiled_class_hash // "unknown"')
  elif jq -e 'map(select(.error)) | .[0].error // "" | test("already declared"; "i")' \
      <<<"$declared" >/dev/null; then
    class_hash=$expected_hash
    compiled_hash="(already declared by a previous run)"
  else
    echo "  FAIL declare: $(jq -c '.' <<<"$declared")"
    failures=$((failures + 1))
    continue
  fi
  check "declared class hash = release artifact class hash" "$class_hash" "$expected_hash"
  echo "  class hash:          $class_hash"
  echo "  compiled class hash: $compiled_hash"

  # Deploy through the UDC; constructor(public_key: Array<felt252>) -> 29 followed by the key.
  address=$(sncast_json deploy --url "$RPC/rpc" --class-hash "$class_hash" \
      --constructor-calldata 29 "${KEY[@]}" \
    | jq -r 'map(select(.contract_address)) | .[0].contract_address // empty')
  if [ -z "$address" ]; then
    echo "  FAIL deploy"
    failures=$((failures + 1))
    continue
  fi
  echo "  account address:     $address"

  check "get_public_key = reference key" "$(call_raw "$address" get_public_key)" "$EXPECTED_KEY"
  check "is_valid_signature(msg, ${#sig[@]}-felt signature) = VALIDATED" \
    "$(call_raw "$address" is_valid_signature "$MSG" "${#sig[@]}" "${sig[@]}" | norm)" "$VALIDATED"
  check "is_valid_signature(msg + 1, same signature) = 0" \
    "$(call_raw "$address" is_valid_signature "$OTHER_MSG" "${#sig[@]}" "${sig[@]}" | norm)" "0x0"
done

if [ "$failures" -ne 0 ]; then
  echo "==> $failures check(s) failed"
  exit 1
fi
echo "==> All checks passed"
