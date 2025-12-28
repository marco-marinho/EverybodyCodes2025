import gleam/int
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
