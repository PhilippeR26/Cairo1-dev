// Key rotation, class upgrade and SNIP-9 outside execution, with OZ's rotation reference data.
// Those signatures are bound to the account address 'FALCON_ACCOUNT' (`account_address()`).
use openzeppelin_interfaces::accounts::FeltArrayAccountABIDispatcherTrait;
use openzeppelin_interfaces::src9::{ISRC9_V2Dispatcher, ISRC9_V2DispatcherTrait, OutsideExecution};
use openzeppelin_interfaces::upgrades::{IUpgradeableDispatcher, IUpgradeableDispatcherTrait};
use snforge_std::{
    start_cheat_block_timestamp_global, start_cheat_caller_address, start_cheat_chain_id_global,
};
use crate::falcon_512::fixture::{msg, public_key, signature};
use crate::falcon_512::rotation_fixture::{
    accept_ownership_hash, accept_ownership_signature, account_address, new_public_key,
    outside_execution_signature,
};
use crate::utils::{class_hash, deploy, deploy_at, direct, direct_class, hint_class};

// ---------- Key rotation ----------

fn assert_rotation(class_name: ByteArray, accept_signature: Array<felt252>, old_signature: Array<felt252>) {
    let address = account_address();
    let account = deploy_at(class_name, address, public_key());
    start_cheat_caller_address(address, address);
    account.set_public_key(new_public_key(), accept_signature.span());

    assert_eq!(account.get_public_key().span(), new_public_key().span());
    assert_eq!(
        account.is_valid_signature(accept_ownership_hash(), accept_signature), starknet::VALIDATED,
    );
    assert_eq!(account.is_valid_signature(msg(), old_signature), 0);
}

fn rotate_from_other_caller(class_name: ByteArray, accept_signature: Array<felt252>) {
    let account = deploy_at(class_name, account_address(), public_key());
    account.set_public_key(new_public_key(), accept_signature.span());
}

fn rotate_with_bad_acceptance(class_name: ByteArray, wrong_signature: Array<felt252>) {
    let address = account_address();
    let account = deploy_at(class_name, address, public_key());
    start_cheat_caller_address(address, address);
    account.set_public_key(new_public_key(), wrong_signature.span());
}

#[test]
fn test_rotation_hint() {
    assert_rotation(hint_class(), accept_ownership_signature(), signature());
}

#[test]
fn test_rotation_direct() {
    assert_rotation(direct_class(), direct(accept_ownership_signature()), direct(signature()));
}

#[test]
#[should_panic(expected: 'Falcon512: unauthorized')]
fn test_rotation_rejects_other_caller_hint() {
    rotate_from_other_caller(hint_class(), accept_ownership_signature());
}

#[test]
#[should_panic(expected: 'Falcon512: unauthorized')]
fn test_rotation_rejects_other_caller_direct() {
    rotate_from_other_caller(direct_class(), direct(accept_ownership_signature()));
}

// The acceptance signature must come from the new key, over the acceptance message.
#[test]
#[should_panic(expected: 'Falcon512: invalid signature')]
fn test_rotation_rejects_bad_acceptance_hint() {
    rotate_with_bad_acceptance(hint_class(), signature());
}

#[test]
#[should_panic(expected: 'Falcon512: invalid signature')]
fn test_rotation_rejects_bad_acceptance_direct() {
    rotate_with_bad_acceptance(direct_class(), direct(signature()));
}

// ---------- Upgrade ----------

fn upgrade_from_other_caller(class_name: ByteArray) {
    let account = deploy(class_name, public_key());
    IUpgradeableDispatcher { contract_address: account.contract_address }
        .upgrade(class_hash(direct_class()));
}

fn upgrade_to_zero_class_hash(class_name: ByteArray) {
    let account = deploy(class_name, public_key());
    start_cheat_caller_address(account.contract_address, account.contract_address);
    IUpgradeableDispatcher { contract_address: account.contract_address }
        .upgrade(0.try_into().unwrap());
}

fn assert_rotation_survives_upgrade(
    source_class: ByteArray,
    target_class: ByteArray,
    source_accept_signature: Array<felt252>,
    target_accept_signature: Array<felt252>,
) {
    let address = account_address();
    let account = deploy_at(source_class, address, public_key());
    start_cheat_caller_address(address, address);
    account.set_public_key(new_public_key(), source_accept_signature.span());

    IUpgradeableDispatcher { contract_address: address }.upgrade(class_hash(target_class));

    assert_eq!(account.get_public_key().span(), new_public_key().span());
    assert_eq!(
        account.is_valid_signature(accept_ownership_hash(), target_accept_signature),
        starknet::VALIDATED,
    );
}

#[test]
#[should_panic(expected: 'Falcon512: unauthorized')]
fn test_upgrade_rejects_other_caller_hint() {
    upgrade_from_other_caller(hint_class());
}

#[test]
#[should_panic(expected: 'Falcon512: unauthorized')]
fn test_upgrade_rejects_other_caller_direct() {
    upgrade_from_other_caller(direct_class());
}

#[test]
#[should_panic(expected: 'Class hash cannot be zero')]
fn test_upgrade_rejects_zero_class_hash_hint() {
    upgrade_to_zero_class_hash(hint_class());
}

#[test]
#[should_panic(expected: 'Class hash cannot be zero')]
fn test_upgrade_rejects_zero_class_hash_direct() {
    upgrade_to_zero_class_hash(direct_class());
}

#[test]
fn test_rotation_survives_upgrade_hint_to_direct() {
    assert_rotation_survives_upgrade(
        hint_class(),
        direct_class(),
        accept_ownership_signature(),
        direct(accept_ownership_signature()),
    );
}

#[test]
fn test_rotation_survives_upgrade_direct_to_hint() {
    assert_rotation_survives_upgrade(
        direct_class(),
        hint_class(),
        direct(accept_ownership_signature()),
        accept_ownership_signature(),
    );
}

// ---------- SNIP-9 outside execution V2 ----------

// The reference signature covers: caller ANY_CALLER, nonce 5, execute_after 10,
// execute_before 20, no calls, chain id SN_SEPOLIA, signed by `new_public_key()`.
fn outside_execution() -> OutsideExecution {
    OutsideExecution {
        caller: 'ANY_CALLER'.try_into().unwrap(),
        nonce: 5,
        execute_after: 10,
        execute_before: 20,
        calls: array![].span(),
    }
}

fn setup_src9(class_name: ByteArray) -> ISRC9_V2Dispatcher {
    let account = deploy_at(class_name, account_address(), new_public_key());
    start_cheat_chain_id_global('SN_SEPOLIA');
    start_cheat_block_timestamp_global(15);
    ISRC9_V2Dispatcher { contract_address: account.contract_address }
}

fn assert_src9_executes(class_name: ByteArray, signature: Array<felt252>) {
    let src9 = setup_src9(class_name);
    assert!(src9.is_valid_outside_execution_nonce(5));
    src9.execute_from_outside_v2(outside_execution(), signature.span());
    assert!(!src9.is_valid_outside_execution_nonce(5));
}

fn execute_src9_twice(class_name: ByteArray, signature: Array<felt252>) {
    let src9 = setup_src9(class_name);
    src9.execute_from_outside_v2(outside_execution(), signature.span());
    src9.execute_from_outside_v2(outside_execution(), signature.span());
}

fn execute_src9_with_empty_signature(class_name: ByteArray) {
    let src9 = setup_src9(class_name);
    src9.execute_from_outside_v2(outside_execution(), array![].span());
}

#[test]
fn test_src9_executes_from_outside_hint() {
    assert_src9_executes(hint_class(), outside_execution_signature());
}

#[test]
fn test_src9_executes_from_outside_direct() {
    assert_src9_executes(direct_class(), direct(outside_execution_signature()));
}

#[test]
#[should_panic(expected: 'SRC9: duplicated nonce')]
fn test_src9_rejects_replay_hint() {
    execute_src9_twice(hint_class(), outside_execution_signature());
}

#[test]
#[should_panic(expected: 'SRC9: duplicated nonce')]
fn test_src9_rejects_replay_direct() {
    execute_src9_twice(direct_class(), direct(outside_execution_signature()));
}

#[test]
#[should_panic(expected: 'SRC9: invalid signature')]
fn test_src9_rejects_invalid_signature_hint() {
    execute_src9_with_empty_signature(hint_class());
}

#[test]
#[should_panic(expected: 'SRC9: invalid signature')]
fn test_src9_rejects_invalid_signature_direct() {
    execute_src9_with_empty_signature(direct_class());
}
