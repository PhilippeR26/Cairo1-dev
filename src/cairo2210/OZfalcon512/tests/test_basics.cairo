use openzeppelin_interfaces::accounts::{FeltArrayAccountABIDispatcherTrait, ISRC6_ID};
use openzeppelin_interfaces::introspection::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use openzeppelin_interfaces::src9::ISRC9_V2_ID;
use crate::falcon_512::fixture::{msg, public_key, signature};
use crate::utils::{deploy, direct, direct_class, hint_class, try_deploy};

/// Index of `salt_a` in both signature layouts: packed s1 (29 felts) || salt_a || salt_b || ...
const SALT_A_INDEX: u32 = 29;

fn with_altered_salt(signature: Array<felt252>) -> Array<felt252> {
    let mut output = array![];
    let mut index = 0;
    for value in signature {
        if index == SALT_A_INDEX {
            output.append(value + 1);
        } else {
            output.append(value);
        }
        index += 1;
    }
    output
}

fn first_felts(values: Array<felt252>, count: u32) -> Array<felt252> {
    let mut output = array![];
    let mut index = 0;
    for value in values {
        if index == count {
            break;
        }
        output.append(value);
        index += 1;
    }
    output
}

fn zero_key() -> Array<felt252> {
    let mut output = array![];
    for _ in 0..29_u32 {
        output.append(0);
    }
    output
}

fn assert_constructor_sets_key_and_interfaces(class_name: ByteArray) {
    let account = deploy(class_name, public_key());
    assert_eq!(account.get_public_key().span(), public_key().span());

    let src5 = ISRC5Dispatcher { contract_address: account.contract_address };
    assert!(src5.supports_interface(ISRC5_ID));
    assert!(src5.supports_interface(ISRC6_ID));
    assert!(src5.supports_interface(ISRC9_V2_ID));
}

fn assert_valid_signature(class_name: ByteArray, signature: Array<felt252>) {
    let account = deploy(class_name, public_key());
    assert_eq!(account.is_valid_signature(msg(), signature), starknet::VALIDATED);
}

fn assert_rejects_other_message(class_name: ByteArray, signature: Array<felt252>) {
    let account = deploy(class_name, public_key());
    assert_eq!(account.is_valid_signature(msg() + 1, signature), 0);
}

fn assert_rejects_altered_salt(class_name: ByteArray, signature: Array<felt252>) {
    let account = deploy(class_name, public_key());
    assert_eq!(account.is_valid_signature(msg(), with_altered_salt(signature)), 0);
}

fn assert_constructor_rejects_key(class_name: ByteArray, key: Array<felt252>) {
    match try_deploy(class_name, key) {
        Result::Ok(_) => panic!("Deployment with an invalid key should fail"),
        Result::Err(panic_data) => assert_eq!(*panic_data.at(0), 'Falcon512: invalid public key'),
    }
}

#[test]
fn test_constructor_sets_key_and_interfaces_hint() {
    assert_constructor_sets_key_and_interfaces(hint_class());
}

#[test]
fn test_constructor_sets_key_and_interfaces_direct() {
    assert_constructor_sets_key_and_interfaces(direct_class());
}

#[test]
fn test_valid_signature_hint() {
    assert_valid_signature(hint_class(), signature());
}

#[test]
fn test_valid_signature_direct() {
    assert_valid_signature(direct_class(), direct(signature()));
}

#[test]
fn test_rejects_other_message_hint() {
    assert_rejects_other_message(hint_class(), signature());
}

#[test]
fn test_rejects_other_message_direct() {
    assert_rejects_other_message(direct_class(), direct(signature()));
}

#[test]
fn test_rejects_altered_salt_hint() {
    assert_rejects_altered_salt(hint_class(), signature());
}

#[test]
fn test_rejects_altered_salt_direct() {
    assert_rejects_altered_salt(direct_class(), direct(signature()));
}

// A signature of the wrong length is rejected (0), not a panic.
#[test]
fn test_wrong_length_signature_returns_zero() {
    let hint_account = deploy(hint_class(), public_key());
    let direct_account = deploy(direct_class(), public_key());
    assert_eq!(hint_account.is_valid_signature(msg(), direct(signature())), 0);
    assert_eq!(direct_account.is_valid_signature(msg(), signature()), 0);
    assert_eq!(hint_account.is_valid_signature(msg(), array![]), 0);
    assert_eq!(direct_account.is_valid_signature(msg(), array![]), 0);
}

#[test]
fn test_constructor_rejects_short_key_hint() {
    assert_constructor_rejects_key(hint_class(), first_felts(public_key(), 28));
}

#[test]
fn test_constructor_rejects_short_key_direct() {
    assert_constructor_rejects_key(direct_class(), first_felts(public_key(), 28));
}

#[test]
fn test_constructor_rejects_zero_key_hint() {
    assert_constructor_rejects_key(hint_class(), zero_key());
}

#[test]
fn test_constructor_rejects_zero_key_direct() {
    assert_constructor_rejects_key(direct_class(), zero_key());
}
