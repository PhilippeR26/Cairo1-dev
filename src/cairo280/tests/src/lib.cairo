pub mod cairo_keccak_intern;
use core::keccak::{keccak_u256s_be_inputs};

// #[derive(Debug)] for complex type, and println!("{:?}", result);

pub fn add(left: usize, right: usize) -> usize {
    left + right
}

pub fn calc() -> u256 {
    let hbe: u256 = keccak_u256s_be_inputs(
        array![0x0294edd6fc3894b2dc125db885ca7b7d02df30472059d6fb3e53e5e122c632e8].span()
    );
    // let result_be = hbe.reverse_bytes(); //this equals
    // 392791df626408017a264f53fde61065d5a93a32b60171df9d8a46afdf82992d
    hbe
}

#[cfg(test)]
mod tests {
    use super::add;
    use super::calc;
    use super::cairo_keccak_intern::keccak_intern::{add_padding, keccak_add_u256_be};
    use starknet::syscalls::keccak_syscall;
    use core::array::{Span, SpanTrait};
    use core::starknet::SyscallResultTrait;
    use core::keccak::{cairo_keccak, compute_keccak_byte_array, keccak_u256s_le_inputs,keccak_u256s_be_inputs};

    #[test]
    fn test1() {
        let _res: u256 = calc();
        println!("_res test1={:?}", _res);
    }

    #[test]
    fn test1b() {
        let str: ByteArray = "get_balance";
        let res: u256 = compute_keccak_byte_array(@str);
        println!("res test1b= {:?} - {:?} - {}", res, str, str);
        let sel = selector!("get_balance");
        println!("tes test1b-2= {:?}", sel);
    }


    #[test]
    fn test1c() {
        let mut arr: Array<u64> = array![0x6362616f6c6c6548];
        //let mut arr:Array<u64> = array![ 0x48656c6c6f616263 ];
        let remain: u64 = 0;
        let res: u256 = cairo_keccak(ref arr, remain, 0);
        let _sel = selector!("get_balance");
        println!("res test1c= {:?}", res);
    }

    #[test]
    fn test1d() {
        let str: ByteArray = "get_balance";
        let k = core::keccak::compute_keccak_byte_array(@str);
        println!("res test1d-k= {:?} ", k);
        // 9596A35DC88478D604C68085B22B367C D60AD119EBC7333233E49281D4119E3B
        // 3B9E11D48192E4333233C7EB19D10AD6 7C362BB28580C604D67884C85DA39695
        //  39E11D48192E4333233C7EB19D10AD6 7C362BB28580C604D67884C85DA39695

        // Reverse bytes and high/low.
        let k_inv = u256 {
            high: core::integer::u128_byte_reverse(k.low),
            low: core::integer::u128_byte_reverse(k.high),
        };

        println!("res test1d-k_inv= {:?} ", k_inv);
        // Finally apply the bitmask for starknet keccak on felt252:
        let ba_sel = k_inv & 0x03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        println!("res test1d-ba_sel= {:?} ", ba_sel);
        let f: felt252 = ba_sel.try_into().unwrap();
        let sel: felt252 = selector!("get_balance");
        assert_eq!(f, sel);
    }

    #[test]
    // #[ignore]
    fn test_keccak_u256s_be_inputs() {
        let a: Array<u256> = array![
            0x0294edd6fc3894b2dc125db885ca7b7d02df30472059d6fb3e53e5e122c632e8
        ];
        // let a: Array<u256> =
        // array![0x0294edd6fc3894b2dc125db885ca7b7d02df30472059d6fb3e53e5e122c632e8,
        // 0x03b16a255e2233c0d3553e482dac388e4b79c369e59334a5a93976c76124666a];
        let mut input: Span<u256> = a.span();

        // #[derive(Debug)]
        let mut keccak_input: Array::<u64> = Default::default();

        loop {
            match input.pop_front() {
                Option::Some(v) => {
                    keccak_add_u256_be(ref keccak_input, *v);
                    println!("v {:?}", v);
                    println!("tmp keccak_input {:?}", keccak_input);
                },
                Option::None => { break (); },
            };
        };
        println!("keccak_input0 {:?}", keccak_input);
        add_padding(ref keccak_input, 0, 0);
        println!("keccak_input1 {:?}", keccak_input);
        let rr: u256 = keccak_syscall(keccak_input.span()).unwrap_syscall();
        println!("rr= {:?}", rr);
    }

    #[test]
    fn test2() {
        let mut data: Array::<u64> = array![12867972693893157890];
        add_padding(ref data, 0, 0);
        println!("res data test 2= {:?}", data);
        let arr: Span<u64> = data.span();
        let res: u256 = keccak_syscall(arr).unwrap_syscall();
        println!("res test2 = {:?}", res);
    }

    #[test]
    //#[available_gas(2000000)]
    fn it_works() {
        let result = add(2, 2);
        println!("ZORG is back. {result}");
        assert_eq!(result, 4);
        // assert!, assert_eq!, assert_ne!, assert_lt!, assert_le!, assert_gt! and assert_ge!
    }

    #[test]
    #[should_panic]
    fn it_works2() {
        let result = add(2, 2);
        assert_eq!(result, 5);
    }

    #[test]
    fn test3(){
        let a:Array<u256> = array![
        0x0000000000000000000000000000000000000000000000000000000000030201,
        0x0000000000000000000000000000000000000000000000000000000000060504];
        let b:u256= keccak_u256s_le_inputs(a.span());
        println!("res test3-b = {:?}", b);
        let k_inv = u256 {
            high: core::integer::u128_byte_reverse(b.low),
            low: core::integer::u128_byte_reverse(b.high),
        };

        println!("res test3-k_inv= {:?} ", k_inv);
        // Finally apply the bitmask for starknet keccak on felt252:
        let ba_sel = k_inv & 0x03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        let f: felt252 = ba_sel.try_into().unwrap();
        println!("res test3-f= {} ", f);
    }

    #[test]
    fn test4(){
        let a:Array<u256> = array![0x0000000000000000000000000000000000000000000000000000000000030201,
         0x0000000000000000000000000000000000000000000000000000000000060504];
        let b:u256= keccak_u256s_be_inputs(a.span());
        println!("res test3-b = {:?}", b);
        let k_inv = u256 {
            high: core::integer::u128_byte_reverse(b.low),
            low: core::integer::u128_byte_reverse(b.high),
        };

        println!("res test3-k_inv= {:?} ", k_inv);
        // Finally apply the bitmask for starknet keccak on felt252:
        let ba_sel = k_inv & 0x03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        let f: felt252 = ba_sel.try_into().unwrap();
        println!("res test3-f= {} ", f);
    }
}
