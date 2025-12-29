import gleam/int
import gleam/list
import gleam/result
import gleam/string
import util

fn parse_line(line: String) -> List(Int) {
  string.split(line, "|")
  |> list.map(fn(x) {
    let assert Ok(v) = int.parse(x)
    v
  })
}

fn part1() -> String {
  let input = util.read_input_lines(4, 1)
  let gears = input |> list.map(fn(x) { int.parse(x) |> result.unwrap(0) })
  let first = list.first(gears) |> result.unwrap(0)
  let last = list.last(gears) |> result.unwrap(0)
  let result = { first * 2025 } / last
  result |> int.to_string
}

fn part2() -> String {
  let input = util.read_input_lines(4, 2)
  let gears = input |> list.map(fn(x) { int.parse(x) |> result.unwrap(0) })
  let first = list.first(gears) |> result.unwrap(0)
  let last = list.last(gears) |> result.unwrap(0)
  let result = { { last * 10_000_000_000_000 } + first + 1 } / first
  result |> int.to_string
}

fn part3() -> String {
  let input = util.read_input_lines(4, 3)
  let assert Ok(first) = list.first(input) |> result.try(int.parse)
  let assert Ok(last) = list.last(input) |> result.try(int.parse)
  let middle =
    input
    |> list.filter(fn(x) { string.contains(x, "|") })
    |> list.map(parse_line)
  let assert [denominator_parts, numerator_parts] = list.transpose(middle)
  let numerator = list.fold(numerator_parts, first, fn(acc, x) { acc * x })
  let denominator = list.fold(denominator_parts, last, fn(acc, x) { acc * x })
  let result = { numerator * 100 } / denominator
  result |> int.to_string
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
