import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn read_input(quest: Int, part: Int) -> String {
  let path =
    "data/quest"
    <> int.to_string(quest) |> string.pad_start(2, "0")
    <> "_"
    <> int.to_string(part)
    <> ".txt"
  let assert Ok(content) = simplifile.read(path)
  content
}

pub fn read_input_lines(quest: Int, part: Int) -> List(String) {
  read_input(quest, part)
  |> string.split("\n")
}

pub fn wrap_index(index: Int, size: Int) -> Int {
  { { index % size } + size } % size
}

pub fn strided_range(start: Int, end: Int, step: Int) -> List(Int) {
  case step {
    0 -> []
    _ if step > 0 && start > end -> []
    _ if step < 0 && start < end -> []
    _ -> do_stride(start, end, step, [])
  }
}

fn do_stride(current: Int, end: Int, step: Int, acc: List(Int)) -> List(Int) {
  case step {
    _ if step > 0 && current > end -> list.reverse(acc)
    _ if step < 0 && current < end -> list.reverse(acc)
    _ -> do_stride(current + step, end, step, [current, ..acc])
  }
}

pub fn count_occurrences(items: List(a)) -> dict.Dict(a, Int) {
  list.fold(items, dict.new(), fn(counts, item) {
    let current = dict.get(counts, item) |> result.unwrap(0)
    dict.insert(counts, item, current + 1)
  })
}

pub fn force_unwrap(res: Result(a, b)) -> a {
  case res {
    Ok(val) -> val
    Error(_) -> panic as "Called force_unwrap on an Error value"
  }
}

pub fn first(ilist: List(a)) -> a {
  let assert Ok(result) = list.first(ilist)
  result
}

pub fn last(ilist: List(a)) -> a {
  let assert Ok(result) = list.last(ilist)
  result
}

pub fn zip3(list1: List(a), list2: List(b), list3: List(c)) -> List(#(a, b, c)) {
  case list1, list2, list3 {
    [h1, ..t1], [h2, ..t2], [h3, ..t3] -> [#(h1, h2, h3), ..zip3(t1, t2, t3)]
    _, _, _ -> []
  }
}

pub fn count_set_bits(n: Int) -> Int {
  count_set_bits_helper(n, 0)
}

fn count_set_bits_helper(n: Int, count: Int) -> Int {
  case n {
    0 -> count
    _ -> {
      case n % 2 {
        1 -> count_set_bits_helper(int.bitwise_shift_right(n, 1), count + 1)
        _ -> count_set_bits_helper(int.bitwise_shift_right(n, 1), count)
      }
    }
  }
}
