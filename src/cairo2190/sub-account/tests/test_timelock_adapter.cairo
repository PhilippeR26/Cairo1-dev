use starknet::ContractAddress;
use starknet::account::Call;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, start_cheat_block_timestamp, stop_cheat_block_timestamp,
};
use sub_account::interfaces::{
    IERC20Dispatcher, IERC20DispatcherTrait, ITimelockAdapterDispatcher,
    ITimelockAdapterDispatcherTrait, ISubAccountDispatcher, ISubAccountDispatcherTrait,
};

const DELAY: u64 = 60;
const WINDOW: u64 = 300;
const T0: u64 = 1000;

fn deploy_erc20() -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let (addr, _) = contract.deploy(@array![]).unwrap();
    addr
}

fn deploy_timelock(owner: ContractAddress, delay: u64, window: u64) -> ContractAddress {
    let contract = declare("TimelockTransferAdapter").unwrap().contract_class();
    let mut cd = array![];
    owner.serialize(ref cd);
    delay.serialize(ref cd);
    window.serialize(ref cd);
    let (addr, _) = contract.deploy(@cd).unwrap();
    addr
}

fn deploy_subaccount(owner: ContractAddress) -> ContractAddress {
    let contract = declare("SubAccount").unwrap().contract_class();
    let (addr, _) = contract.deploy(@array![owner.into()]).unwrap();
    addr
}

// holder funded with 1000 and having approved `adapter` for 500
fn funded_holder(token: ContractAddress, adapter: ContractAddress) -> ContractAddress {
    let holder: ContractAddress = 'holder'.try_into().unwrap();
    let erc = IERC20Dispatcher { contract_address: token };
    erc.mint(holder, 1000);
    start_cheat_caller_address(token, holder);
    erc.approve(adapter, 500);
    stop_cheat_caller_address(token);
    holder
}

#[test]
fn test_request_then_execute_after_delay() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    let token = deploy_erc20();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let holder = funded_holder(token, adapter);
    let erc = IERC20Dispatcher { contract_address: token };
    let tl = ITimelockAdapterDispatcher { contract_address: adapter };

    start_cheat_block_timestamp(adapter, T0);
    start_cheat_caller_address(adapter, holder);

    // phase 1: arm, nothing moves
    tl.request_transfer(token, recipient, 200);
    assert(erc.balance_of(recipient) == 0, 'SHOULD_NOT_TRANSFER_YET');
    let p = tl.pending(holder, token, recipient, 200);
    assert(p.executable_at == T0 + DELAY, 'BAD_EXECUTABLE_AT');
    assert(p.expires_at == T0 + DELAY + WINDOW, 'BAD_EXPIRES_AT');

    // phase 2: after the delay, same request executes
    start_cheat_block_timestamp(adapter, T0 + DELAY);
    tl.request_transfer(token, recipient, 200);

    stop_cheat_caller_address(adapter);
    stop_cheat_block_timestamp(adapter);

    assert(erc.balance_of(recipient) == 200, 'BAD_RECIPIENT_BAL');
    assert(erc.balance_of(holder) == 800, 'BAD_HOLDER_BAL');
    let cleared = tl.pending(holder, token, recipient, 200);
    assert(cleared.executable_at == 0, 'PENDING_NOT_CLEARED');
}

#[test]
#[should_panic(expected: 'TOO_EARLY')]
fn test_rerequest_too_early() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    let token = deploy_erc20();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let holder = funded_holder(token, adapter);
    let tl = ITimelockAdapterDispatcher { contract_address: adapter };

    start_cheat_caller_address(adapter, holder);
    start_cheat_block_timestamp(adapter, T0);
    tl.request_transfer(token, recipient, 200);
    // one second before the delay elapses
    start_cheat_block_timestamp(adapter, T0 + DELAY - 1);
    tl.request_transfer(token, recipient, 200);
}

#[test]
fn test_expired_window_rearms() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    let token = deploy_erc20();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let holder = funded_holder(token, adapter);
    let erc = IERC20Dispatcher { contract_address: token };
    let tl = ITimelockAdapterDispatcher { contract_address: adapter };

    start_cheat_caller_address(adapter, holder);
    start_cheat_block_timestamp(adapter, T0);
    tl.request_transfer(token, recipient, 200);

    // past expires_at (T0+DELAY+WINDOW) -> re-arms, does not transfer
    let t_expired = T0 + DELAY + WINDOW + 1;
    start_cheat_block_timestamp(adapter, t_expired);
    tl.request_transfer(token, recipient, 200);
    assert(erc.balance_of(recipient) == 0, 'SHOULD_HAVE_REARMED');
    let p = tl.pending(holder, token, recipient, 200);
    assert(p.executable_at == t_expired + DELAY, 'BAD_REARMED_BOUND');

    // after the new delay -> executes
    start_cheat_block_timestamp(adapter, t_expired + DELAY);
    tl.request_transfer(token, recipient, 200);
    stop_cheat_caller_address(adapter);
    stop_cheat_block_timestamp(adapter);
    assert(erc.balance_of(recipient) == 200, 'BAD_RECIPIENT_BAL');
}

#[test]
fn test_multiple_pending() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let r1: ContractAddress = 'r1'.try_into().unwrap();
    let r2: ContractAddress = 'r2'.try_into().unwrap();
    let token = deploy_erc20();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let holder = funded_holder(token, adapter);
    let erc = IERC20Dispatcher { contract_address: token };
    let tl = ITimelockAdapterDispatcher { contract_address: adapter };

    start_cheat_caller_address(adapter, holder);
    start_cheat_block_timestamp(adapter, T0);
    // two distinct requests pending at the same time
    tl.request_transfer(token, r1, 100);
    tl.request_transfer(token, r2, 200);

    start_cheat_block_timestamp(adapter, T0 + DELAY);
    tl.request_transfer(token, r1, 100); // execute #1
    tl.request_transfer(token, r2, 200); // execute #2
    stop_cheat_caller_address(adapter);
    stop_cheat_block_timestamp(adapter);

    assert(erc.balance_of(r1) == 100, 'BAD_R1_BAL');
    assert(erc.balance_of(r2) == 200, 'BAD_R2_BAL');
    assert(erc.balance_of(holder) == 700, 'BAD_HOLDER_BAL');
}

#[test]
fn test_owner_can_change_durations() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let tl = ITimelockAdapterDispatcher { contract_address: adapter };

    start_cheat_caller_address(adapter, owner);
    tl.set_delay(120);
    tl.set_window(600);
    stop_cheat_caller_address(adapter);

    assert(tl.delay() == 120, 'BAD_DELAY');
    assert(tl.window() == 600, 'BAD_WINDOW');
}

#[test]
#[should_panic(expected: 'NOT_OWNER')]
fn test_set_delay_non_owner() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    // no caller cheat -> caller is the test address, not the owner
    ITimelockAdapterDispatcher { contract_address: adapter }.set_delay(120);
}

#[test]
fn test_duration_change_does_not_affect_pending() {
    let owner: ContractAddress = 'admin'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    let token = deploy_erc20();
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let holder = funded_holder(token, adapter);
    let erc = IERC20Dispatcher { contract_address: token };
    let tl = ITimelockAdapterDispatcher { contract_address: adapter };

    // arm under DELAY=60
    start_cheat_block_timestamp(adapter, T0);
    start_cheat_caller_address(adapter, holder);
    tl.request_transfer(token, recipient, 200);
    stop_cheat_caller_address(adapter);

    // owner raises delay to 600 AFTER the request was armed
    start_cheat_caller_address(adapter, owner);
    tl.set_delay(600);
    stop_cheat_caller_address(adapter);

    // the already-armed request still executes at the OLD bound (T0+60), not T0+600
    start_cheat_block_timestamp(adapter, T0 + DELAY);
    start_cheat_caller_address(adapter, holder);
    tl.request_transfer(token, recipient, 200);
    stop_cheat_caller_address(adapter);
    stop_cheat_block_timestamp(adapter);

    assert(erc.balance_of(recipient) == 200, 'FROZEN_BOUND_BROKEN');
}

fn request_call(adapter: ContractAddress, token: ContractAddress, recipient: ContractAddress, amount: u256) -> Call {
    let mut cd = array![];
    token.serialize(ref cd);
    recipient.serialize(ref cd);
    amount.serialize(ref cd);
    Call { to: adapter, selector: selector!("request_transfer"), calldata: cd.span() }
}

#[test]
fn test_end_to_end_via_subaccount() {
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    let recipient: ContractAddress = 'recipient'.try_into().unwrap();
    let token = deploy_erc20();
    let sub = deploy_subaccount(owner);
    let adapter = deploy_timelock(owner, DELAY, WINDOW);
    let erc = IERC20Dispatcher { contract_address: token };
    let sub_disp = ISubAccountDispatcher { contract_address: sub };

    erc.mint(sub, 1000);

    start_cheat_caller_address(sub, owner);
    sub_disp.set_adapter(adapter, true);
    sub_disp.approve_token(token, adapter, 500);

    let call = request_call(adapter, token, recipient, 200);

    // phase 1: arm (caller seen by the adapter is the sub-account)
    start_cheat_block_timestamp(adapter, T0);
    sub_disp.execute(call);
    assert(erc.balance_of(recipient) == 0, 'SHOULD_NOT_TRANSFER_YET');

    // phase 2: after the delay, execute
    start_cheat_block_timestamp(adapter, T0 + DELAY);
    sub_disp.execute(call);
    stop_cheat_caller_address(sub);
    stop_cheat_block_timestamp(adapter);

    assert(erc.balance_of(recipient) == 200, 'BAD_RECIPIENT_BAL');
    assert(erc.balance_of(sub) == 800, 'BAD_SUB_BAL');
}
