use core::poseidon::poseidon_hash_span;

use super::structure::IStructHash;

#[derive(Drop, Serde)]
pub struct LongString {
    pub to_store: Array<felt252>,
}

pub const LONG_STRING_TYPE_HASH: felt252 = selector!("\"Message\"(\"to_store\":\"shortstring*\")");

pub impl StructHashLongString of IStructHash<LongString> {
    fn hash_struct(self: @LongString) -> felt252 {
        let mut to_hash: Array<felt252> = array![LONG_STRING_TYPE_HASH];
        let arr: Span<felt252> = self.to_store.span();
        let array_f252: felt252=poseidon_hash_span(arr);
        to_hash.append(array_f252);
        // for i in arr {
        //     to_hash.append(*i);
        // };
        poseidon_hash_span(to_hash.span())
    }
}
