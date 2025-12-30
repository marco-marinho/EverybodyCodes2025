import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import gleam/string
import util

type Rules =
  dict.Dict(String, set.Set(String))

fn count_unique(current_char: String, current_length: Int, rules: Rules) -> Int {
  case current_length {
    11 -> 1
    x -> {
      let count_this = case x {
        y if y >= 7 -> 1
        _ -> 0
      }
      let next_ones = case dict.get(rules, current_char) {
        Ok(allowed) ->
          set.fold(allowed, 0, fn(acc, next_char) {
            acc + count_unique(next_char, current_length + 1, rules)
          })
        Error(_) -> 0
      }
      count_this + next_ones
    }
  }
}

fn is_valid(name: String, rules: Rules) -> Bool {
  name
  |> string.to_graphemes
  |> list.window(2)
  |> list.all(fn(pair) {
    let assert [a, b] = pair
    case dict.get(rules, a) {
      Ok(allowed) -> set.contains(allowed, b)
      Error(_) -> False
    }
  })
}

fn parse(part: Int) -> #(List(String), Rules) {
  let input = util.read_input_lines(7, part)
  let names = list.first(input) |> util.force_unwrap |> string.split(",")
  let rules =
    input
    |> list.drop(2)
    |> list.fold(dict.new(), fn(acc, line) {
      let halves = string.split(line, " > ")
      let key = list.first(halves) |> util.force_unwrap
      let values =
        list.drop(halves, 1)
        |> list.first
        |> util.force_unwrap
        |> string.split(",")
        |> set.from_list
      dict.insert(acc, key, values)
    })
  #(names, rules)
}

fn part1() -> String {
  let #(names, rules) = parse(1)
  let res = names |> list.filter(fn(name) { is_valid(name, rules) })
  res |> list.first |> util.force_unwrap
}

fn part2() -> String {
  let #(names, rules) = parse(2)
  names
  |> list.index_map(fn(name, index) {
    case is_valid(name, rules) {
      True -> index + 1
      False -> 0
    }
  })
  |> list.reduce(fn(acc, x) { acc + x })
  |> util.force_unwrap
  |> int.to_string
}

fn part3() -> String {
  let #(names, rules) = parse(3)
  names
  |> list.sort(fn(x, y) { int.compare(string.length(x), string.length(y)) })
  let filtered_names =
    names
    |> list.fold([], fn(acc, name) {
      let is_redundant =
        list.any(acc, fn(existing) { string.starts_with(name, existing) })
      case is_redundant {
        True -> acc
        False -> [name, ..acc]
      }
    })
  filtered_names
  |> list.map(fn(name) {
    case is_valid(name, rules) {
      True ->
        count_unique(
          string.last(name) |> util.force_unwrap,
          string.length(name),
          rules,
        )
      False -> 0
    }
  })
  |> list.reduce(fn(acc, x) { acc + x })
  |> util.force_unwrap
  |> int.to_string
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
