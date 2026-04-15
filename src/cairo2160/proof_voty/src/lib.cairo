// handle vote
// Coded with Cairo 2.15.2
// contract not audited ; use at your own risks.

#[starknet::interface]
pub trait IMerkleVerify<TContractState> {
    fn main(
        self: @TContractState,
        // ================== PUBLIC INPUTS (visibles dans la preuve)
        merkle_root: felt252,
        vote: u8,
        nullifier: felt252,
        round: felt252,
        // ================== PRIVATE INPUTS (cachés par la preuve)
        member_leaf: felt252, // hash de ton identifiant membre
        merkle_proof: Array<felt252>, // siblings (profondeur max ~20-25 ok en browser)
        secret: felt252 // ton secret privé (généré localement, jamais envoyé)
    ) -> (felt252, u8, felt252);
}

#[starknet::contract]
mod PrivateVoteVerifierMultiRound {
    use core::array::ArrayTrait;
    use core::poseidon::poseidon_hash_span;
    use core::traits::Into;
    use starknet::{ContractAddress};

    // ──────────────────────────────────────────────
    // Storage
    // ──────────────────────────────────────────────
    #[storage]
    struct Storage {}

    // ──────────────────────────────────────────────
    // Events
    // ──────────────────────────────────────────────
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        VoteVerified: VoteVerified,
        VoteAdded: VoteAdded,
        RoundClosed: RoundClosed,
    }

    #[derive(Drop, starknet::Event)]
    struct VoteVerified {
        #[key]
        round: felt252,
        #[key]
        voter: ContractAddress,
        #[key]
        vote: u8,
        #[key]
        nullifier: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct VoteAdded {
        #[key]
        round: felt252,
        #[key]
        vote: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct RoundClosed {
        #[key]
        round: felt252,
    }

    // ──────────────────────────────────────────────
    // Constructor
    // ──────────────────────────────────────────────
    #[constructor]
    fn constructor(ref self: ContractState) {}

    fn merkle_verify(leaf: felt252, mut proof: Array<felt252>, root: felt252) -> bool {
        let mut hash = leaf;
        let mut i = 0_u32;
        while i < proof.len() {
            // println!("a,b: 0x{:x} 0x{:x}", hash, *proofEnter[i]);
            let hash_uint256: u256 = hash.into();
            let proof_item: u256 = (*proof[i]).into();
            if hash_uint256 < proof_item {
                hash = poseidon_hash_span(array![hash, *proof[i]].into());
                // println!("case 1: 0x{:x}", hash);
            } else {
                hash = poseidon_hash_span(array![*proof[i], hash].into());
                // println!("case 2: 0x{:x}", hash);

            }
            i += 1;
        }

        hash == root
    }

    // ──────────────────────────────────────────────
    // Trait pour les méthodes external
    // ──────────────────────────────────────────────
    #[abi(embed_v0)]
    impl ProofVerifyContract of super::IMerkleVerify<ContractState> {
        fn main(
            self: @ContractState,
            // ================== PUBLIC INPUTS (visibles dans la preuve)
            merkle_root: felt252,
            vote: u8,
            nullifier: felt252,
            round: felt252,
            // ================== PRIVATE INPUTS (cachés par la preuve)
            member_leaf: felt252, // hash de ton identifiant membre
            merkle_proof: Array<felt252>, // siblings (profondeur max ~20-25 ok en browser)
            secret: felt252 // ton secret privé (généré localement, jamais envoyé)
        ) -> (felt252, u8, felt252) { // retour = (merkle_root, vote, nullifier)
            // 1. Vote valide ?
            assert(vote >= 0_u8 && vote <= 3_u8, 'Invalid vote option');

            // 2. Nullifier correct ?
            let computed_nullifier = poseidon_hash_span(array![secret, round].span());
            assert(computed_nullifier == nullifier, 'Invalid nullifier');

            // 3. Appartenance à la liste des membres ?
            let is_member = merkle_verify(member_leaf, merkle_proof, merkle_root);
            assert(is_member, 'Not a member');

            // Tout est bon → on retourne les valeurs publiques
            // (le prover S-two prouvera que ces outputs sont corrects)
            (merkle_root, vote, nullifier)
        }
    }
}
