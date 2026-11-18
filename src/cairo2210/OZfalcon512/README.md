# OpenZeppelin Falcon-512 accounts, compiled with Cairo 2.21

## Purpose

Two post-quantum Falcon-512 account classes, OpenZeppelin's presets compiled unmodified with
Cairo/Scarb 2.21.0, as test material for starknet.js (which today supports S2morrow Falcon accounts
only) and for the starknet.js workshop demo scripts. This package contains no contract of its own:
it builds OZ's presets, proves their behaviour with OZ's reference data, measures them, and
deploys them on a local devnet.

| Variant | Class | Signature | Validation gas |
|---|---|---|---|
| Hint | `Falcon512ShakeAccountUpgradeable` | 60 felts: `pack(s1) ‖ salt_a ‖ salt_b ‖ pack(s1·h)` | about 32 M |
| Direct | `Falcon512ShakeDirectAccountUpgradeable` | 31 felts: `pack(s1) ‖ salt_a ‖ salt_b` | about 44 M |

Both accounts provide:

| Feature | Entrypoints |
|---|---|
| SRC6 transaction validation and execution | `__validate__`, `__execute__`, `is_valid_signature` / `isValidSignature` |
| Declare and deploy-account validation | `__validate_declare__`, `__validate_deploy__(class_hash, salt, public_key: Array<felt252>)` |
| Read the public key | `get_public_key` / `getPublicKey` → `Array<felt252>` (29 felts) |
| Change the public key | `set_public_key(new_public_key: Array<felt252>, signature: Span<felt252>)` / `setPublicKey`: self-call only, plus an acceptance signature by the new key |
| SNIP-9 outside execution V2 | `execute_from_outside_v2`, `is_valid_outside_execution_nonce` |
| Class upgrade | `upgrade(new_class_hash)`: self-call only |
| SRC5 introspection | `supports_interface` (SRC5, SRC6, SRC9 V2) |

Constructor: `constructor(public_key: Array<felt252>)`.

## Provenance

| Item | Value |
|---|---|
| Source | OpenZeppelin Contracts for Cairo, tag [`v4.1.0-rc.0`](https://github.com/OpenZeppelin/cairo-contracts/releases/tag/v4.1.0-rc.0) (pre-release, 2026-11-16) |
| Commit | `37b0ce066755a68ee7af44bccb746d02cb0da8a9` ("PQ Accounts optimizations (#1784)") |
| Tag tarball sha256 | `8e048f2920884d175c30cc51267f94a8c6c7bf478b53a4b18e93223b74f2733c` (`gh api repos/OpenZeppelin/cairo-contracts/tarball/v4.1.0-rc.0`) |
| Hint class | `openzeppelin_presets::falcon_512_shake_account::Falcon512ShakeAccountUpgradeable` |
| Direct class | `openzeppelin_presets::falcon_512_shake_direct_account::Falcon512ShakeDirectAccountUpgradeable` |
| Modifications | None: both presets are compiled unmodified, through `build-external-contracts` |
| Date | 2026-11-18 |

## Validation of OZ under Cairo 2.21

OZ tested this tag with Scarb 2.18.0 and Starknet Foundry 0.64.0. Before building the classes,
OZ's own Falcon verification commands (`CONTRIBUTING.md`, `.github/workflows/test.yml`) were run on
the tag tarball, once with Scarb 2.18.0 and once with Scarb 2.21.0, both with Starknet Foundry
0.64.1, so that differences come from the compiler only.

| OZ command | Scarb 2.18.0 | Scarb 2.21.0 |
|---|---|---|
| `scarb --release lint -p openzeppelin_account --features falcon_fast_tests --test --deny-warnings` | pass | pass |
| `scarb --release lint -p openzeppelin_presets --features falcon_presets_tests --test --deny-warnings` | pass | pass |
| `snforge test -p openzeppelin_account … falcon_512 --skip every_basis_vector` | 98 passed | 98 passed |
| `snforge test -p openzeppelin_presets … falcon_512 --gas-report` | 31 passed | 31 passed |
| `snforge test -p openzeppelin_account … every_basis_vector --max-n-steps 150000000` | 2 passed | 2 passed |
| `scarb --release build -p openzeppelin_presets` | pass | **fail** (1) |
| `python3 scripts/falcon_512/check_resources.py` | pass | not run (needs the build) |
| `python3 scripts/falcon_512/check_fixtures.py` and its `unittest` suite | not run (2) | not run (2) |

1. OZ's manifests set `allowed-libfuncs-list.name = "experimental"`. Cairo 2.21 removed that list
   (`crates/cairo-lang-starknet-classes/src/allowed_libfuncs_lists/` holds `all`, `audited` and
   `experimental` at `v2.18.0`, only `all` and `audited` at `v2.21.0`), so Scarb 2.21 stops with
   `No libfunc list named 'experimental' is known.` This is a manifest setting, not OZ code. The
   only libfuncs that `experimental` (2.18) had and `audited` lacks are `felt252_add_const`,
   `felt252_sub_const`, `felt252_mul_const` and `felt252_div_const`. Built with Scarb's default
   list, as this package does, both presets compile under 2.21 without any libfunc warning, and
   their Sierra program is identical to the one OZ's workspace produces under 2.21 for its tests.
2. These scripts need Python ≥ 3.11 (`tomllib`); the machine has 3.10.12. They recompute the
   reference data independently of Cairo and do not depend on the compiler: skipped by decision.
   The same reference data is exercised by the Cairo tests above and by this package's tests.

Validation gas of OZ's reference transaction (`--gas-report`, OZ budget tests):

| Entrypoint | Hint, 2.18 | Hint, 2.21 | Direct, 2.18 | Direct, 2.21 |
|---|---|---|---|---|
| `__validate__` | 31,955,045 | 31,955,045 | 44,182,445 | 44,167,095 |
| `__validate_declare__` | 31,952,775 | 31,952,775 | 44,180,175 | 44,164,825 |
| `__validate_deploy__` | 32,007,175 | 32,007,175 | 44,234,575 | 44,219,225 |

Sizes (2.18: `check_resources.py`; 2.21: same measurements on the 2.21 build):

| Class | Sierra felts | CASM felts | Artifact bytes |
|---|---|---|---|
| Hint, 2.18 | 46,514 | 32,801 | 2,050,762 |
| Hint, 2.21 | 46,395 | 32,708 | 2,043,222 |
| Direct, 2.18 | 42,612 | 37,417 | 1,789,539 |
| Direct, 2.21 | 42,575 | 37,613 | 1,787,171 |

Class hashes (`starkli class-hash`):

| Class | Scarb 2.18.0 (OZ workspace) | Scarb 2.21.0 |
|---|---|---|
| Hint | `0x028a203cd70bafbd37abc7e1d17f2e933a7375fec23008021c334b6316854620` | `0x014660ce3739fbde6e33d994cebd6a9fb20e800516b2e1b6c253d4d09baa9ae0` |
| Direct | `0x062e1217e0c47ad48b06fba6827c75c2b828e8225500a3f9c69f38416cca6c24` | `0x016111958d61eedfa5a950b608997abb4981b548f1862d620cc9247461ddeeb1` |

## Classes

Built by `scarb --release build` (Scarb 2.21.0, Cairo 2.21.0, Sierra 1.9.5,
`contract_class_version` 0.1.0) into `target/release/`:

| Class | Sierra artifact (`.contract_class.json`) and CASM (`.compiled_contract_class.json`) | Class hash |
|---|---|---|
| Hint | `oz_falcon512_Falcon512ShakeAccountUpgradeable` | `0x014660ce3739fbde6e33d994cebd6a9fb20e800516b2e1b6c253d4d09baa9ae0` |
| Direct | `oz_falcon512_Falcon512ShakeDirectAccountUpgradeable` | `0x016111958d61eedfa5a950b608997abb4981b548f1862d620cc9247461ddeeb1` |

The Sierra programs and class hashes are identical to those OZ's own workspace produces under
Scarb 2.21.0: the consuming package does not change the class. `Scarb.lock` pins the OZ dependency
to commit `37b0ce066755a68ee7af44bccb746d02cb0da8a9`.

Compiled class hashes:

| Class | Accepted by starknet-devnet 0.11.0 (`scripts/run_devnet.sh`) | Poseidon hash of Scarb's CASM (`starkli class-hash`, starkli 0.3.7) |
|---|---|---|
| Hint | `0x70a9d08c913d3f61f940241547141e4688ea59c87e0ece0caf400aa37a31f7f` | `0x0254b2195de50eddf474ee7b3fd09e4c179fcf5e5a8c6794e8ff567af10d6957` |
| Direct | `0x3928427a4e2fef7542c9ece069a561f928bafbf1d57efb10e4f0abc52d2af` | `0x014d3b03c6ceda29b30aa46fde0ca253b6a902e1984360c5fd1d84ae3701227d` |

The two columns differ for the same CASM. The devnet value is the one sncast 0.64.1 sent in the
declare transaction and the devnet accepted; it is presumably the BLAKE2s-based compiled class hash
used since Starknet 0.14.1 (not verified here). Use the devnet column to declare on a devnet of
that generation.

## Sizes

`scripts/check_sizes.sh` (shell + jq port of OZ's `check_resources.py`) lowers each class to CASM
with universal-sierra-compiler 2.10.2, measures it, and exits non-zero on any excess. Its
`class_bytes` computation reproduces OZ's Python value byte for byte on the 2.18 classes.

| Metric | Hint (2.21) | Direct (2.21) | OZ budget | Starknet limit |
|---|---|---|---|---|
| Sierra felts | 46,395 | 42,575 | 50,000 | 81,920 |
| CASM felts (universal-sierra-compiler = Scarb) | 32,708 | 37,613 | 41,000 | 81,920 |
| Artifact bytes | 2,043,222 | 1,787,171 | 2,200,000 | — |
| Declared class bytes | 2,044,016 | 1,787,965 | 2,200,000 | 4,089,446 |

For comparison, under 2.18 (OZ's `check_resources.py`): hint 46,514 / 32,801 / 2,050,762 /
2,051,556, direct 42,612 / 37,417 / 1,789,539 / 1,790,333. The direct class's CASM grew by 196
felts under 2.21; everything else shrank slightly. Starknet limits are those of the chain-info
page as encoded by OZ; recheck them on network upgrades.

## Validation gas

Sierra gas of OZ's reference transaction (`tests/test_validation_gas.cairo`, run with
`--gas-report`). The validation limit is 100,000,000 (Starknet 0.14.2, `validate_max_sierra_gas`);
the tests also assert OZ's budgets: 80 M overall, 34 M (hint) and 47 M (direct).

| Entrypoint | Hint, OZ 2.18 | Hint, this package (2.21) | Direct, OZ 2.18 | Direct, this package (2.21) |
|---|---|---|---|---|
| `__validate__` | 31,955,045 | 31,955,045 | 44,182,445 | 44,167,095 |
| `__validate_declare__` | 31,952,775 | 31,952,775 | 44,180,175 | 44,164,825 |
| `__validate_deploy__` | 32,007,175 | 32,007,175 | 44,234,575 | 44,219,225 |

The package figures equal OZ's own 2.21 figures (same class). The values printed by the tests
(`get_unspent_gas()` before and after the call) are slightly higher, by 94,000 to 148,000, because
they include the dispatcher overhead. SHAKE-256 rejection sampling makes the cost depend on the
message and signature: these are measurements on one reference transaction, not worst-case bounds.

## Libfuncs

`Scarb.toml` sets no `allowed-libfuncs-list`, so Scarb 2.21's default list applies. The release
build of both classes reports **no libfunc warning**. The only warnings are 221 occurrences of
`unknown manifest field ... scarb-version`, coming from OZ's manifests (Scarb 2.21 no longer knows
that field); they do not affect the build.

This shows that the classes use no libfunc outside Scarb's default list. It does not prove that a
public network accepts Sierra 1.9.5 or these libfuncs: that depends on the network's own
configuration.

## Build & test

Toolchain pinned in [`.tool-versions`](./.tool-versions) (resolved by asdf inside this directory):
`scarb 2.21.0`, `starknet-foundry 0.64.1`. universal-sierra-compiler, jq and starkli must be on
PATH for the scripts.

```bash
# from this directory
scarb --release build                                     # always the release profile
snforge test --release --max-n-steps 5000000              # 39 passing (also: scarb run test)
snforge test --release --max-n-steps 5000000 --gas-report # with the gas table
scripts/check_sizes.sh                                    # sizes against limits and budgets
```

Scarb prints about 220 `unknown manifest field ... scarb-version` warnings coming from OZ's
manifests, and snforge prints `external contracts not found for selectors: oz_falcon512::*`
(this package has no contract of its own). Both are harmless.

Tests (OZ reference data, both variants each time):

| File | Covers |
|---|---|
| `tests/test_basics.cairo` | key read back after deployment; SRC5/SRC6/SRC9 V2 interfaces; reference signature accepted; other message, altered salt and wrong-length signatures rejected (0, no panic); short or all-zero key refused at deployment |
| `tests/test_validation_gas.cairo` | gas of `__validate__`, `__validate_declare__`, `__validate_deploy__` against OZ's budgets; `__validate__` with a wrong hash panics `'Falcon512: invalid signature'` |
| `tests/test_rotation_upgrade_src9.cairo` | `set_public_key` (accepted, old key then rejected, other caller and bad acceptance refused); `upgrade` (other caller and zero class hash refused, key kept across a hint ↔ direct upgrade); SNIP-9 execution, replay and empty signature |

The reference data in `tests/falcon_512/` is a verbatim copy of OZ's files (3-line provenance
header added). To check it against the tag:

```bash
for f in fixture rotation_fixture; do
  tail -n +4 tests/falcon_512/$f.cairo | diff - <(gh api \
    "repos/OpenZeppelin/cairo-contracts/contents/packages/test_common/src/falcon_512/$f.cairo?ref=v4.1.0-rc.0" \
    -H "Accept: application/vnd.github.raw") && echo "$f: identical"
done
```

## Devnet

Prerequisite: a running `starknet-devnet` (tested with 0.11.0, `--seed 0`, RPC spec 0.10.2) at
`http://127.0.0.1:5050` (override with `RPC=...`). The script never starts a devnet.

```bash
scripts/run_devnet.sh
```

It builds the release artifacts, imports the first predeployed devnet account as `devnet0` into
`accounts.json` (git-ignored: it holds a private key), then for each class:

1. declares it with `sncast --scarb-profile release declare`, checks that the declared class hash
   equals `starkli class-hash` of the `target/release` artifact, and prints the compiled class hash
   carried by the declare transaction ("already declared" on a re-run is recognised);
2. deploys one account through the UDC with OZ's reference key: constructor calldata `29` followed
   by the 29 felts of `public_key()` from `tests/falcon_512/fixture.cairo`;
3. calls `get_public_key` (expects `0x1d` + the 29 felts), `is_valid_signature(msg, signature)`
   (expects `0x56414c4944`, `'VALID'`; 60 felts on the hint account, the first 31 on the direct
   one) and `is_valid_signature(msg + 1, signature)` (expects `0x0`).

Sample output (addresses change on every run, the UDC salt being random):

```
==> Falcon512ShakeAccountUpgradeable
  OK   declared class hash = release artifact class hash
  class hash:          0x14660ce3739fbde6e33d994cebd6a9fb20e800516b2e1b6c253d4d09baa9ae0
  compiled class hash: 0x70a9d08c913d3f61f940241547141e4688ea59c87e0ece0caf400aa37a31f7f
  account address:     0x01d79283197c3169456e91f4a73563ac4d0e979aef9cd02d567e8da774cb7fb5
  OK   get_public_key = reference key
  OK   is_valid_signature(msg, 60-felt signature) = VALIDATED
  OK   is_valid_signature(msg + 1, same signature) = 0
==> Falcon512ShakeDirectAccountUpgradeable
  ...
==> All checks passed
```

Starknet-devnet 0.11.0 accepts these Sierra 1.9.5 classes. The deployed accounts cannot send
transactions: OZ's reference key comes without its secret key, and signing in OZ's format is not
yet available in starknet.js.

## Formats

Summary of OZ's contract-specific encodings; the normative text is the "Key and signature
encoding" section of OZ's `packages/account/README.md` at the tag.

- **Public key**: 512 residues modulo 12289 in NTT evaluation order, packed into 29 felts. Each
  full felt holds 18 residues: nine base-12289 digits in its low 128 bits and nine in its high
  128 bits, least-significant digit first; the last felt holds eight digits in its low half. The
  all-zero key is refused. Constructor calldata: `29` followed by the 29 felts.
- **Signatures**: direct = `pack(s1) ‖ salt_a ‖ salt_b` (31 felts); hint = the same followed by
  `pack(s1·h mod (x^512 + 1, 12289))` (60 felts). Each salt felt encodes 20 bytes, little-endian.
  Dropping the 29-felt suffix of a hint signature gives a valid direct signature, so signature
  bytes must not be used as a message identifier.
- **Hash-to-point**: SHAKE-256 over `salt_a (20 bytes LE) ‖ salt_b (20 bytes LE) ‖ message_hash
  (32 bytes LE)`, output read as big-endian 16-bit words, words ≥ 61445 discarded, the others
  reduced modulo 12289, until 512 coefficients.
- **Key change acceptance message**, signed by the new key:
  `Poseidon('StarkNet Message', 'accept_ownership', account_address, poseidon_hash_span(current_key))`.
  It carries no chain id, nonce or expiry: an acceptance proof is not single-use.

This is the FALCON submission's verification relation, **not FN-DSA (FIPS 206)**. starknet.js's
current S2morrow format differs in hash-to-point (Poseidon), salt and signature layout, but uses
the same packed public key.

## Caveats

- OZ v4.1.0-rc.0 is a pre-release: formats may still change before 4.1.0.
- The classes are compiled with Cairo 2.21, which OZ did not test (OZ used 2.18). OZ's own suite
  passes under 2.21 (see above), except its release build, which requests a libfunc list that
  Cairo 2.21 removed.
- Acceptance by a public network of Sierra 1.9.5 and of the libfuncs these classes use is not
  verified; only starknet-devnet 0.11.0 was tried.
- Gas figures are measurements on one reference transaction; SHAKE-256 rejection sampling makes
  the cost input-dependent.
- The reference key and signatures are OZ test material, without a secret key: accounts deployed
  with them cannot send transactions. Never use them in production.

## Layout

```
Scarb.toml                       OZ dependency (git tag), build-external-contracts, release usage
Scarb.lock                       pins OZ commit 37b0ce0 (tracked on purpose)
.tool-versions                   scarb 2.21.0, starknet-foundry 0.64.1
snfoundry.toml                   sncast profile for the local devnet
src/lib.cairo                    no contract (the presets come from OZ)
tests/lib.cairo                  test crate root
tests/falcon_512/                verbatim copies of OZ's fixture.cairo and rotation_fixture.cairo
tests/utils.cairo                class names, deploy helpers, direct-signature prefix
tests/test_basics.cairo          deployment, interfaces, signature checks
tests/test_validation_gas.cairo  validation gas and budgets
tests/test_rotation_upgrade_src9.cairo  key change, upgrade, SNIP-9
scripts/check_sizes.sh           sizes against limits and budgets (shell + jq)
scripts/run_devnet.sh            declare, deploy and check on a local devnet
target/release/                  Sierra and CASM of both classes
```

Design notes (repo root): `docs/superpowers/specs/2026-11-18-oz-falcon512-accounts-design.md` and
`docs/superpowers/plans/2026-11-18-oz-falcon512-accounts.md`.
