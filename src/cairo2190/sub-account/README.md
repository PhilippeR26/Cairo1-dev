# Starknet Sub-Accounts + Adapters

A minimal, self-contained demo of the **sub-account** pattern on Starknet (the
idea popularized by [Nostra](https://nostra.finance/faq/)), tested end-to-end on
a local Devnet.

## Objective

A single wallet often concentrates all risk: the key that signs also controls
every token. The sub-account pattern **ring-fences risk** by splitting funds
across dedicated contracts that can only perform a narrow, pre-authorized set of
actions:

- A **main account** holds the private key and signs. It holds nothing at risk
  directly.
- Each **sub-account** is an isolated contract that holds a *small* balance and
  may only relay calls to a whitelist of **adapter** contracts.
- Each **adapter** performs one precise, authorized task (here: a capped token
  transfer to a fixed recipient).

If an adapter is ever compromised, the blast radius is bounded to the allowance
that one sub-account granted it — the main account and every other sub-account
are untouched.

> 📄 See [`subaccount-flow.pdf`](./subaccount-flow.pdf) for a visual diagram of
> the execution flow and the signing model.

## Who signs, and when? (the core insight)

There is exactly **one signature** per action — the main account's. The
sub-account and the adapter hold **no key**; they authorize by reading
`get_caller_address()`, and the whole chain runs inside **one atomic
transaction**. If any `assert` fails, nothing moves.

```
🔑 You sign ONE tx (main account key)  ──►  __validate__ / __execute__
        │
        ▼  call_contract_syscall            caller seen = Main account
   SubAccount.execute(call)                 assert caller == owner
        │  assert adapters[call.to] == true (whitelist)
        ▼  call_contract_syscall            caller seen = SubAccount
   Adapter.pull_and_transfer(amount)        assert amount <= cap
        │
        ▼  transfer_from(SubAccount, ..)     caller seen = Adapter
   MockERC20                                uses the SubAccount→Adapter allowance
```

`get_caller_address()` shifts at every hop: **Main account → SubAccount →
Adapter**. No second signature is ever required.

## Architecture

Four contracts, in [`src/`](./src):

| Contract | File | Role |
|---|---|---|
| `SubAccount` | [`sub_account.cairo`](./src/sub_account.cairo) | Owner-gated relay + adapter whitelist. Holds the ring-fenced tokens. |
| `CappedTransferAdapter` | [`capped_transfer_adapter.cairo`](./src/capped_transfer_adapter.cairo) | Adapter #1: transfer a fixed token to a fixed recipient, amount ≤ cap. |
| `TimelockTransferAdapter` | [`timelock_transfer_adapter.cairo`](./src/timelock_transfer_adapter.cairo) | Adapter #2: large transfers guarded by a two-phase timelock (request, then re-request after a delay). |
| `MockERC20` | [`mock_erc20.cairo`](./src/mock_erc20.cairo) | Minimal test token (permissionless `mint`). |

Interfaces (`IERC20`, `IAdapter`, `ITimelockAdapter`, `ISubAccount`) live in
[`interfaces.cairo`](./src/interfaces.cairo). Both adapters are whitelisted and
funded through the exact same `SubAccount` flow — they differ only in the guard
they enforce (a per-transfer cap vs. a time delay).

### `SubAccount` interface

```cairo
fn set_adapter(ref self, adapter: ContractAddress, allowed: bool);      // owner-only: manage whitelist
fn approve_token(ref self, token, spender: ContractAddress, amount: u256); // owner-only: grant an adapter an allowance
fn execute(ref self, call: Call) -> Span<felt252>;                       // owner-only: relay to a whitelisted adapter
fn owner(self) -> ContractAddress;
fn is_adapter(self, adapter: ContractAddress) -> bool;
```

`execute` enforces, **in order**:
1. `assert(get_caller_address() == owner)` → panics `NOT_OWNER`
2. `assert(adapters[call.to] == true)` → panics `ADAPTER_NOT_ALLOWED`
3. only then `call_contract_syscall(call.to, call.selector, call.calldata)`

### `CappedTransferAdapter` interface

```cairo
fn pull_and_transfer(ref self, amount: u256);  // assert(amount <= cap); transfer_from(caller, recipient, amount)
fn token(self) -> ContractAddress;
fn recipient(self) -> ContractAddress;
fn cap(self) -> u256;
```

`token`, `recipient`, and `cap` are frozen at construction. Because the transfer
uses `from = get_caller_address()`, the adapter can **only ever move its
caller's own funds**, up to the allowance that caller granted it.

### `TimelockTransferAdapter` interface

For large, long-term-storage transfers where the guard is *time*, not a cap. A
single entrypoint is called **twice**: the first call arms a request, and the
same request re-submitted after a configurable delay (within a window) executes
it — a mandatory cooling-off period before big funds move.

```cairo
fn request_transfer(ref self, token, recipient: ContractAddress, amount: u256);
fn set_delay(ref self, delay: u64);    // owner-only
fn set_window(ref self, window: u64);  // owner-only
fn pending(self, caller, token, recipient: ContractAddress, amount: u256) -> PendingRequest;
fn owner(self) -> ContractAddress;
fn delay(self) -> u64;
fn window(self) -> u64;
```

`request_transfer(token, recipient, amount)` — with `now = get_block_timestamp()`
and `key = poseidon(caller, token, recipient, amount)`:

1. **no pending entry** → arm `{ executable_at: now + delay, expires_at: now + delay + window }`, emit `TransferRequested`.
2. **entry exists**: `now < executable_at` → revert `TOO_EARLY`; within `[executable_at, expires_at]` → **execute** (clear entry, then `transfer_from(caller, recipient, amount)`), emit `TransferExecuted`; past `expires_at` → re-arm.

Notes:
- **Any ERC-20** (`token` is per-request) and **any recipient/amount**.
- **Multiple requests can be pending at once** — each distinct `(caller, token, recipient, amount)` has its own slot (keyed by hash). Trade-off: pending entries can't be enumerated on-chain; query one by its identity, or read the events for history.
- **Bounds are frozen at request time**, so `set_delay`/`set_window` (owner-only) only affect *future* requests, never already-armed ones.

## How it works, end to end

The demo scenario (see [`scripts/run_devnet.sh`](./scripts/run_devnet.sh)):

1. Deploy `MockERC20`, `SubAccount(owner)`, `CappedTransferAdapter(token, recipient, cap=500)`.
2. `MockERC20.mint(subAccount, 1000)` — fund the ring-fenced vault.
3. owner → `SubAccount.set_adapter(adapter, true)` — whitelist the adapter.
4. owner → `SubAccount.approve_token(token, adapter, 500)` — grant a bounded allowance.
5. owner → `SubAccount.execute(Call{ to: adapter, selector: pull_and_transfer, calldata: [200] })`.
6. Result: **recipient +200, sub-account −200** (final balances `200` / `800`).

The negative paths are covered by tests: a non-owner caller, a non-whitelisted
target, a removed adapter, and an over-cap amount each revert the whole call.

## Build & test

Toolchain is pinned in [`.tool-versions`](./.tool-versions) (resolved via asdf
inside this directory): `scarb 2.19.0`, `starknet-foundry 0.62.0`,
`starknet-devnet 0.9.0`.

```bash
# from this directory
scarb build
snforge test        # 17 passing: both adapters, timelock two-phase, security guards
```

## Run the end-to-end demo on a local Devnet

```bash
# terminal 1 — start Devnet with deterministic pre-deployed accounts
starknet-devnet --seed 0

# terminal 2 — capped-transfer adapter (adapter #1)
./scripts/run_devnet.sh
# expected: recipient balance 0xc8 (200), sub-account balance 0x320 (800)

# terminal 2 — timelock adapter (adapter #2): request, reject-if-too-early,
# advance Devnet time, re-request, execute
./scripts/run_devnet_timelock.sh
# expected: rejected (TOO_EARLY) before the delay, then recipient 0xc8 / sub 0x320
```

Each script imports the first pre-deployed Devnet account (via the JSON-RPC
`devnet_getPredeployedAccounts` method), uses it as the sub-account owner/signer,
and computes the inner adapter selector with `starkli selector`. Output is parsed
with `jq`. The timelock script fast-forwards the chain with `devnet_increaseTime`
instead of sleeping, and re-runs cleanly (it recovers already-declared class
hashes). Both regenerate `accounts.json` (git-ignored — it holds a private key).

## Layout

```
src/
  interfaces.cairo               IERC20 / IAdapter / ITimelockAdapter / ISubAccount
  mock_erc20.cairo               test token
  capped_transfer_adapter.cairo  adapter #1: capped transfer
  timelock_transfer_adapter.cairo adapter #2: two-phase timelock
  sub_account.cairo              owner-gated relay + whitelist
tests/
  test_erc20.cairo
  test_adapter.cairo             capped adapter
  test_timelock_adapter.cairo    timelock adapter (2 phases, multiple pending, frozen bounds)
  test_sub_account.cairo         happy path + 4 security guards
scripts/run_devnet.sh            Devnet e2e — capped adapter
scripts/run_devnet_timelock.sh   Devnet e2e — timelock adapter (two phases + time travel)
snfoundry.toml                   sncast profile (local Devnet)
subaccount-flow.pdf              execution / signing diagram
```

Design notes: `docs/superpowers/specs/2026-07-03-starknet-sub-account-design.md`,
`docs/superpowers/specs/2026-07-03-timelock-transfer-adapter-design.md`, and
`docs/superpowers/plans/2026-07-03-starknet-sub-account.md` (repo root).

## Scope & caveats

This is a teaching/testing scaffold, not production code:

- `MockERC20.mint` is intentionally permissionless.
- Two adapters are included (`CappedTransferAdapter`, `TimelockTransferAdapter`);
  the whitelist supports as many as you like.
- `SubAccount` is a plain callee contract (checks caller + whitelist), **not** a
  full SNIP-6 account — the main account is the only signer.
- No spending limits on the sub-account itself, and no sub-account factory.
- The timelock adapter can't enumerate pending requests on-chain (query by
  identity / read events), and its `owner` is trusted to set sane durations.
