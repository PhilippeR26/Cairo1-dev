#!/usr/bin/env bash
# Check both Falcon account classes against Starknet declaration limits and OpenZeppelin's
# in-repo budgets. Shell + jq port of OZ scripts/falcon_512/check_resources.py (v4.1.0-rc.0).
# Prereq: `scarb --release build`, universal-sierra-compiler and jq on PATH.
#
# Usage: scripts/check_sizes.sh
# Env overrides: TARGET_DIR (default target/release), BUDGET_SIERRA_FELTS (50000),
#   BUDGET_CASM_FELTS (41000), BUDGET_ARTIFACT_BYTES (2200000), BUDGET_CLASS_BYTES (2200000).
# Output: one JSON line per class. Exit: 0 = within limits and budgets, 1 = an excess,
#   2 = an artifact or a tool is missing.
set -euo pipefail
cd "$(dirname "$0")/.."   # -> package root (src/cairo2210/OZfalcon512)

TARGET_DIR="${TARGET_DIR:-target/release}"
PACKAGE="oz_falcon512"
CLASSES=(Falcon512ShakeAccountUpgradeable Falcon512ShakeDirectAccountUpgradeable)

# Starknet declaration limits (https://docs.starknet.io/learn/cheatsheets/chain-info), as in OZ.
MAX_BYTECODE_FELTS=81920
MAX_CLASS_BYTES=4089446
# OZ budgets, strictly below 70% of each protocol limit.
BUDGET_SIERRA_FELTS="${BUDGET_SIERRA_FELTS:-50000}"
BUDGET_CASM_FELTS="${BUDGET_CASM_FELTS:-41000}"
BUDGET_ARTIFACT_BYTES="${BUDGET_ARTIFACT_BYTES:-2200000}"
BUDGET_CLASS_BYTES="${BUDGET_CLASS_BYTES:-2200000}"

for tool in jq universal-sierra-compiler; do
  command -v "$tool" >/dev/null || { echo "ERROR: $tool not found on PATH" >&2; exit 2; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

status=0
check() { # check <contract> <metric> <value> <bound>
  if [ "$3" -gt "$4" ]; then
    echo "ERROR $1: $2 $3 exceeds $4" >&2
    status=1
  fi
}

for class in "${CLASSES[@]}"; do
  sierra="$TARGET_DIR/${PACKAGE}_${class}.contract_class.json"
  scarb_casm="$TARGET_DIR/${PACKAGE}_${class}.compiled_contract_class.json"
  for file in "$sierra" "$scarb_casm"; do
    [ -f "$file" ] || { echo "ERROR: $file not found; run 'scarb --release build' first" >&2; exit 2; }
  done

  # Lower Sierra to CASM the way OZ does, with universal-sierra-compiler.
  casm="$tmp/$class.casm.json"
  universal-sierra-compiler compile-contract --sierra-path "$sierra" --output-path "$casm" >/dev/null

  sierra_felts=$(jq '.sierra_program | length' "$sierra")
  casm_felts=$(jq '.bytecode | length' "$casm")
  scarb_casm_felts=$(jq '.bytecode | length' "$scarb_casm")
  artifact_bytes=$(stat -c %s "$sierra")
  # Declared class payload: the gateway's SierraContractClass has no debug info and an ABI string.
  class_bytes=$(jq -cj '{sierra_program, contract_class_version, entry_points_by_type,
      abi: (if (.abi | type) == "string" then .abi else (.abi | tojson) end)}' "$sierra" | wc -c)

  jq -cn --arg contract "$class" \
    --argjson sierra_felts "$sierra_felts" --argjson casm_felts "$casm_felts" \
    --argjson scarb_casm_felts "$scarb_casm_felts" --argjson artifact_bytes "$artifact_bytes" \
    --argjson class_bytes "$class_bytes" \
    '{contract: $contract, sierra_felts: $sierra_felts, casm_felts: $casm_felts,
      scarb_casm_felts: $scarb_casm_felts, artifact_bytes: $artifact_bytes,
      class_bytes: $class_bytes}'

  check "$class" sierra_felts "$sierra_felts" "$MAX_BYTECODE_FELTS"
  check "$class" casm_felts "$casm_felts" "$MAX_BYTECODE_FELTS"
  check "$class" class_bytes "$class_bytes" "$MAX_CLASS_BYTES"
  check "$class" sierra_felts "$sierra_felts" "$BUDGET_SIERRA_FELTS"
  check "$class" casm_felts "$casm_felts" "$BUDGET_CASM_FELTS"
  check "$class" artifact_bytes "$artifact_bytes" "$BUDGET_ARTIFACT_BYTES"
  check "$class" class_bytes "$class_bytes" "$BUDGET_CLASS_BYTES"
done

exit "$status"
