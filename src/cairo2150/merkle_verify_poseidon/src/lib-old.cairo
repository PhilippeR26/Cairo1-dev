// verification of a Poseidon MerkleTree proof created by the npm starknet-merkle-tree library
// Coded with Cairo 2.4.0
// contract not audited ; use at your own risks.

use starknet::ContractAddress;

#[starknet::interface]
trait IMerkleVerify<TContractState> {
    fn get_root(self: @TContractState) -> felt252;
    fn verify_from_leaf_hash(
        self: @TContractState, leaf_hash: felt252, proof: Array<felt252>
    ) -> bool;
    fn verify_from_leaf_array(
        self: @TContractState, leaf_array: Array<felt252>, proof: Array<felt252>
    ) -> bool;
    fn verify_from_leaf_airdrop(
        self: @TContractState, address: ContractAddress, amount: u256, proof: Array<felt252>
    ) -> bool;
    fn hash_leaf_array(self: @TContractState, leaf: Array<felt252>) -> felt252;
}


#[starknet::contract]
mod merkle {
    use starknet::storage::StoragePointerReadAccess;
use starknet::storage::StoragePointerWriteAccess;
use core::traits::Into;
    use super::IMerkleVerify;
    use starknet::{ContractAddress};
    use core::poseidon::poseidon_hash_span;
    use core::hash::HashStateExTrait;
    use poseidon::{PoseidonTrait, HashState};
    use hash::{HashStateTrait, Hash};
    use array::{ArrayTrait, SpanTrait};

    #[storage]
    struct Storage {
        merkle_root: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, merkle_root: felt252) {
        self.merkle_root.write(merkle_root);
    }

    // recursive calculation of proof hash
    fn hash_proof(leaf: felt252, proofEnter: Array<felt252>) -> felt252 {
        let mut proof = proofEnter;
        if (proof.len() == 0_u32) {
            return leaf;
        }
        let mut hash: felt252 = 0_felt252;
        if integer::u256_from_felt252(leaf) < integer::u256_from_felt252(*proof[0_u32]) {
            hash = poseidon_hash_span(leaf, *proof[0_u32]);
        } else {
            hash = poseidon_hash_span(*proof[0_u32], leaf);
        }
        proof.pop_front().unwrap();
        let result = hash_proof(hash, proof);
        result
    }


    #[external(v0)]
    impl MerkleVerifyContract of super::IMerkleVerify<ContractState> {
        fn get_root(self: @ContractState) -> felt252 {
            self.merkle_root.read()
        }

        fn verify_from_leaf_hash(
            self: @ContractState, leaf_hash: felt252, proof: Array<felt252>
        ) -> bool {
            let hash: felt252 = hash_proof(leaf_hash, proof);
            let root: felt252 = self.merkle_root.read();
            if hash == root {
                return true;
            }
            return false;
        }

        fn verify_from_leaf_array(
            self: @ContractState, leaf_array: Array<felt252>, proof: Array<felt252>
        ) -> bool {
            let leaf_hash = self.hash_leaf_array(leaf_array);
            self.verify_from_leaf_hash(leaf_hash, proof)
        }

        fn verify_from_leaf_airdrop(
            self: @ContractState, address: ContractAddress, amount: u256, proof: Array<felt252>
        ) -> bool {
            let hash_leaf: felt252 = PoseidonTrait::new()
                .update(0)
                .update_with(address)
                .update_with(amount.low)
                .update_with(amount.high)
                .update(3) // 3= length of data (address + amount low & high)
                .finalize();
            self.verify_from_leaf_hash(hash_leaf, proof)
        }

        fn hash_leaf_array(self: @ContractState, mut leaf: Array<felt252>) -> felt252 {
            let len: felt252 = leaf.len().into();
            let mut call_data: Array<felt252> = ArrayTrait::new();
            call_data.append(0);
            // loop {
            //     match leaf.pop_front() {
            //         Option::Some(numb) => {
            //             call_data.append(numb);
                        
            //         },
            //         Option::None => { break; },
            //     }
            // };
            Serde::serialize(@leaf, ref call_data);
            call_data.append(len);
            poseidon_hash_span(call_data.span())
        }
    }
}
