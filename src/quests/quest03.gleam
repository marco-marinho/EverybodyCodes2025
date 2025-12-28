import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import util

fn parse_input(part: Int) -> List(Int) {
  let assert Ok(input) = util.read_input_lines(3, part) |> list.first
  string.split(input, ",")
  |> list.map(fn(x) {
    let assert Ok(v) = int.parse(x)
    v
  })
}

fn part1() -> String {
  let values = parse_input(1)
  list.unique(values) |> list.fold(0, fn(acc, x) { acc + x }) |> int.to_string
}

fn part2() -> String {
  let values = parse_input(2)
  let sorted = list.unique(values) |> list.sort(int.compare)
  let result = list.take(sorted, 20) |> list.fold(0, fn(acc, x) { acc + x })
  result |> int.to_string
}

fn part3() -> String {
  let values = parse_input(3)
  let occurrences = util.count_occurrences(values)
  let assert Ok(max_occurrences) =
    dict.values(occurrences) |> list.max(int.compare)
  max_occurrences |> int.to_string
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
