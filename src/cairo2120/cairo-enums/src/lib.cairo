// Coded with Cairo 2.12.0

#[derive(Copy, Drop, Serde)]
struct Point {
    x: u64,
    y: u32,
}

#[derive(Copy, Drop, Serde)]
struct Point2 {
    thickness: u64,
    location: Point,
}

#[derive(Copy, Drop, Serde)]
struct Empty {}

#[derive(Copy, Drop, Serde)]
struct Dog {
    age: u16,
    colors: Span<u32>,
}

#[derive(Copy, Drop, Serde)]
struct Cat {
    age: u16,
    legs: (u8, u16, u32, u64),
}

#[derive(Copy, Drop, Serde)]
struct Horse {
    age: u16,
    legs_color: [u16; 4],
}

#[derive(Copy, Drop, Serde)]
struct Truck {
    power: u32,
    turbo: Option<u8>,
}

#[derive(Copy, Drop, Serde)]
struct Destruction {
    area: u128,
    res: Result<u8, u64>,
}

#[derive(Copy, Drop, Serde)]
enum StatusEnum {
    Success: (u64, u32),
    NoAnswer,
    Error,
}

#[derive(Copy, Drop, Serde)]
enum MyEnum {
    Success: u8,
    LocationError: Point,
    Status: StatusEnum,
    TwoErrors: [u32; 2],
    ErrorList: Span<u256>,
    Parents: (u64, u128),
    Damage: Option<u8>,
    Report: Result<u32, u64>,
    Empty,
}

#[derive(Copy, Drop, Serde)]
struct ExecutionReport {
    message: MyEnum,
    description: bytes31,
}

#[starknet::interface]
trait ITestOption<TContractState> {
    fn option_bn(self: @TContractState, x: Option<u16>) -> Option<u16>;
    fn option_array(self: @TContractState, x: Option<Array<u8>>) -> Option<Array<u8>>;
    fn option_fixed_array(self: @TContractState, x: Option<[u32; 3]>) -> Option<[u32; 3]>;
    fn option_tuple(
        self: @TContractState, x: Option<(u32, Array<u32>)>,
    ) -> Option<(u32, Array<u32>)>;
    fn option_option_bn(self: @TContractState, x: Option<Option<u16>>) -> Option<Option<u16>>;
    fn option_result(self: @TContractState, x: Option<Result<u8, u16>>) -> Option<Result<u8, u16>>;
    fn option_struct(self: @TContractState, x: Option<Point>) -> Option<Point>;
    fn option_enum(self: @TContractState, x: Option<MyEnum>) -> Option<MyEnum>;
    fn array_option_bn(self: @TContractState, x: Array<Option<u16>>) -> Array<Option<u16>>;
    fn array_enum(self: @TContractState, x: Array<MyEnum>) -> Array<MyEnum>;
    fn write_option_bn(ref self: TContractState, x: Option<u16>);
    fn option_point(self: @TContractState, x: Option<Point>) -> Option<Point>;

    fn result_bn(self: @TContractState, x: Result<u8, u16>) -> Result<u8, u16>;
    fn result_array(
        self: @TContractState, x: Result<Array<u8>, Array<u16>>,
    ) -> Result<Array<u8>, Array<u16>>;
    fn result_fixed_array(
        self: @TContractState, x: Result<[u32; 3], [u16; 2]>,
    ) -> Result<[u32; 3], [u16; 2]>;
    fn result_tuple(
        self: @TContractState, x: Result<(u32, Array<u32>), (u16, Array<u16>)>,
    ) -> Result<(u32, Array<u32>), (u16, Array<u16>)>;
    fn result_result_bn(
        self: @TContractState, x: Result<Result<u8, u16>, u32>,
    ) -> Result<Result<u8, u16>, u32>;
    fn result_option(self: @TContractState, x: Result<u8, Option<u32>>) -> Result<u8, Option<u32>>;
    fn result_struct(self: @TContractState, x: Result<u8, Point>) -> Result<u8, Point>;
    fn result_enum(self: @TContractState, x: Result<u8, MyEnum>) -> Result<u8, MyEnum>;
    fn write_result_bn(ref self: TContractState, x: Result<u8, u16>);

    fn struct_point(self: @TContractState, x: Point) -> Point;
    fn struct_point2(self: @TContractState, x: Point2) -> Point2;
    fn struct_Empty(self: @TContractState, x: Empty) -> Empty;
    fn struct_Cat(self: @TContractState, x: Cat) -> Cat;
    fn struct_Dog(self: @TContractState, x: Dog) -> Dog;
    fn struct_Horse(self: @TContractState, x: Horse) -> Horse;
    fn struct_Truck(self: @TContractState, x: Truck) -> Truck;
    fn struct_Destruction(self: @TContractState, x: Destruction) -> Destruction;
    fn struct_enum(self: @TContractState, x: ExecutionReport) -> ExecutionReport;
    fn write_struct_point(ref self: TContractState, x: Point);
    fn custom_enum(self: @TContractState, x: MyEnum) -> MyEnum;
    fn write_custom_enum(ref self: TContractState, x: MyEnum);
    fn tuple_bool(self: @TContractState, x: (bool, bool)) -> (bool, bool);
}

#[starknet::contract]
mod test_enums {
    use super::{Cat, Destruction, Dog, Empty, ExecutionReport, Horse, MyEnum, Point, Point2, Truck};

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl TestOption of super::ITestOption<ContractState> {
        fn option_bn(self: @ContractState, x: Option<u16>) -> Option<u16> {
            x
        }
        fn option_array(self: @ContractState, x: Option<Array<u8>>) -> Option<Array<u8>> {
            x
        }
        fn option_fixed_array(self: @ContractState, x: Option<[u32; 3]>) -> Option<[u32; 3]> {
            x
        }
        fn option_tuple(
            self: @ContractState, x: Option<(u32, Array<u32>)>,
        ) -> Option<(u32, Array<u32>)> {
            x
        }
        fn option_option_bn(self: @ContractState, x: Option<Option<u16>>) -> Option<Option<u16>> {
            x
        }
        fn option_result(
            self: @ContractState, x: Option<Result<u8, u16>>,
        ) -> Option<Result<u8, u16>> {
            x
        }
        fn option_struct(self: @ContractState, x: Option<Point>) -> Option<Point> {
            x
        }
        fn option_enum(self: @ContractState, x: Option<MyEnum>) -> Option<MyEnum> {
            x
        }
        fn array_option_bn(self: @ContractState, x: Array<Option<u16>>) -> Array<Option<u16>> {
            x
        }
        fn array_enum(self: @ContractState, x: Array<MyEnum>) -> Array<MyEnum> {
            x
        }
        fn write_option_bn(ref self: ContractState, x: Option<u16>) {}
        fn option_point(self: @ContractState, x: Option<Point>) -> Option<Point> {
            x
        }

        fn result_bn(self: @ContractState, x: Result<u8, u16>) -> Result<u8, u16> {
            x
        }
        fn result_array(
            self: @ContractState, x: Result<Array<u8>, Array<u16>>,
        ) -> Result<Array<u8>, Array<u16>> {
            x
        }
        fn result_fixed_array(
            self: @ContractState, x: Result<[u32; 3], [u16; 2]>,
        ) -> Result<[u32; 3], [u16; 2]> {
            x
        }
        fn result_tuple(
            self: @ContractState, x: Result<(u32, Array<u32>), (u16, Array<u16>)>,
        ) -> Result<(u32, Array<u32>), (u16, Array<u16>)> {
            x
        }
        fn result_result_bn(
            self: @ContractState, x: Result<Result<u8, u16>, u32>,
        ) -> Result<Result<u8, u16>, u32> {
            x
        }
        fn result_option(
            self: @ContractState, x: Result<u8, Option<u32>>,
        ) -> Result<u8, Option<u32>> {
            x
        }
        fn result_struct(self: @ContractState, x: Result<u8, Point>) -> Result<u8, Point> {
            x
        }
        fn result_enum(self: @ContractState, x: Result<u8, MyEnum>) -> Result<u8, MyEnum> {
            x
        }

        fn write_result_bn(ref self: ContractState, x: Result<u8, u16>) {}
        fn struct_point(self: @ContractState, x: Point) -> Point {
            x
        }
        fn struct_point2(self: @ContractState, x: Point2) -> Point2 {
            x
        }
        fn struct_Empty(self: @ContractState, x: Empty) -> Empty {
            x
        }
        fn struct_Cat(self: @ContractState, x: Cat) -> Cat {
            x
        }
        fn struct_Dog(self: @ContractState, x: Dog) -> Dog {
            x
        }
        fn struct_Horse(self: @ContractState, x: Horse) -> Horse {
            x
        }
        fn struct_Truck(self: @ContractState, x: Truck) -> Truck {
            x
        }
        fn struct_Destruction(self: @ContractState, x: Destruction) -> Destruction {
            x
        }
        fn struct_enum(self: @ContractState, x: ExecutionReport) -> ExecutionReport {
            x
        }

        fn write_struct_point(ref self: ContractState, x: Point) {}
        fn custom_enum(self: @ContractState, x: MyEnum) -> MyEnum {
            x
        }
        fn write_custom_enum(ref self: ContractState, x: MyEnum) {}
        fn tuple_bool(self: @ContractState, x: (bool, bool)) -> (bool, bool) {
            x
        }
    }
}
