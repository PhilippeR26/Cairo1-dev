// Validation gas of the OZ reference transaction, measured as in OZ's own preset tests
// (packages/presets/src/tests/test_falcon_512_accounts.cairo at v4.1.0-rc.0).
use core::testing::get_unspent_gas;
use openzeppelin_interfaces::accounts::FeltArrayAccountABIDispatcherTrait;
use snforge_std::{start_cheat_signature_global, start_cheat_transaction_hash_global};
use crate::falcon_512::fixture::{msg, public_key, signature};
use crate::utils::{deploy, direct, direct_class, hint_class};

// Starknet 0.14.2 validate_max_sierra_gas (https://docs.starknet.io/learn/cheatsheets/chain-info).
const VALIDATE_MAX_SIERRA_GAS: u128 = 100000000;
// OZ reserves 20% of the protocol cap.
const VALIDATION_GAS_BUDGET: u128 = VALIDATE_MAX_SIERRA_GAS * 80 / 100;
// OZ per-preset regression budgets.
const HINT_VALIDATION_GAS_BUDGET: u128 = 34000000;
const DIRECT_VALIDATION_GAS_BUDGET: u128 = 47000000;

const INVOKE: u32 = 0;
const DECLARE: u32 = 1;
const DEPLOY: u32 = 2;

fn assert_validation_entrypoint(
    class_name: ByteArray, signature: Array<felt252>, entrypoint: u32, regression_budget: u128,
) {
    let account = deploy(class_name.clone(), public_key());
    start_cheat_transaction_hash_global(msg());
    start_cheat_signature_global(signature.span());
    let gas_before = get_unspent_gas();
    let result = match entrypoint {
        0 => account.__validate__(array![]),
        1 => account.__validate_declare__(0),
        2 => account.__validate_deploy__(0, 0, public_key()),
        _ => panic!("Unknown validation entrypoint"),
    };
    // Includes dispatcher overhead, excludes deployment.
    let gas_used = gas_before - get_unspent_gas();
    println!("{class_name} entrypoint {entrypoint}: {gas_used}");
    assert_eq!(result, starknet::VALIDATED);
    assert!(gas_used <= VALIDATION_GAS_BUDGET, "Validation gas: {gas_used}");
    assert!(gas_used <= regression_budget, "Validation gas regression: {gas_used}");
}

fn validate_with_wrong_hash(class_name: ByteArray, signature: Array<felt252>) {
    let account = deploy(class_name, public_key());
    start_cheat_transaction_hash_global(msg() + 1);
    start_cheat_signature_global(signature.span());
    account.__validate__(array![]);
}

#[test]
#[available_gas(l2_gas: 110000000)]
fn test_hint_invoke_validation_gas() {
    assert_validation_entrypoint(hint_class(), signature(), INVOKE, HINT_VALIDATION_GAS_BUDGET);
}

#[test]
#[available_gas(l2_gas: 110000000)]
fn test_hint_declare_validation_gas() {
    assert_validation_entrypoint(hint_class(), signature(), DECLARE, HINT_VALIDATION_GAS_BUDGET);
}

#[test]
#[available_gas(l2_gas: 110000000)]
fn test_hint_deploy_validation_gas() {
    assert_validation_entrypoint(hint_class(), signature(), DEPLOY, HINT_VALIDATION_GAS_BUDGET);
}

#[test]
#[available_gas(l2_gas: 110000000)]
fn test_direct_invoke_validation_gas() {
    assert_validation_entrypoint(
        direct_class(), direct(signature()), INVOKE, DIRECT_VALIDATION_GAS_BUDGET,
    );
}

#[test]
#[available_gas(l2_gas: 110000000)]
fn test_direct_declare_validation_gas() {
    assert_validation_entrypoint(
        direct_class(), direct(signature()), DECLARE, DIRECT_VALIDATION_GAS_BUDGET,
    );
}

#[test]
#[available_gas(l2_gas: 110000000)]
fn test_direct_deploy_validation_gas() {
    assert_validation_entrypoint(
        direct_class(), direct(signature()), DEPLOY, DIRECT_VALIDATION_GAS_BUDGET,
    );
}

// A signature that does not match the transaction hash makes validation panic (it does not
// return 0), so the transaction is rejected.
#[test]
#[should_panic(expected: 'Falcon512: invalid signature')]
fn test_validate_rejects_wrong_hash_hint() {
    validate_with_wrong_hash(hint_class(), signature());
}

#[test]
#[should_panic(expected: 'Falcon512: invalid signature')]
fn test_validate_rejects_wrong_hash_direct() {
    validate_with_wrong_hash(direct_class(), direct(signature()));
}
