pub type Atomics

pub type AtomicsOptions {
  Signed(Bool)
}

@external(erlang, "atomics", "new")
pub fn new(size: Int, options: List(AtomicsOptions)) -> Atomics

@external(erlang, "atomics", "put")
pub fn put(ref: Atomics, index: Int, value: Int) -> Nil

@external(erlang, "atomics", "get")
pub fn get(ref: Atomics, index: Int) -> Int
