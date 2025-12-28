import gleam/int
import gleam/list
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
