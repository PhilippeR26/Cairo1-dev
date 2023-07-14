#[contract]
mod HelloStarknet {
    #[derive(Copy, Drop)]
    struct Back {
        pa1: felt252,
        pa2: u8,
        pa3: u16,
        pa4: u32,
        pa5: u64,
        pa6: u128,
        pa7: u256,
        pa8: usize,
        pa9: bool,
    }

    #[derive(Drop, Serde)]
    struct Pos2D {
        x: u16,
        y: u16
    }

    #[derive(Drop, Serde)]
    struct Trip {
        origin: Pos2D,
        destination: Pos2D,
        tag: felt252
    }
    #[external]
    fn test1(
        p1: felt252, p2: u8, p3: u16, p4: u32, p5: u64, p6: u128, p7: u256, p8: usize, p9: bool
    ) -> Back {
        Back { pa1: p1, pa2: p2, pa3: p3, pa4: p4, pa5: p5, pa6: p6, pa7: p7, pa8: p8, pa9: p9,  }
    }

    #[view]
    fn test_array_out() -> Array<felt252> {
        let mut a: Array<felt252> = ArrayTrait::new();
        a.append(0_felt252);
        a.append(1_felt252);
        a.append(2_felt252);
        a
    }
}
