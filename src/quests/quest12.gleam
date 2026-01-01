import rslib_ffi

fn part1() -> String {
  let res = rslib_ffi.quest12_1()
  res
}

fn part2() -> String {
  let res = rslib_ffi.quest12_2()
  res
}

fn part3() -> String {
  todo
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
