import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import parallel_map.{MatchSchedulersOnline}
import util

type ComplexNumber {
  ComplexNumber(x: Int, y: Int)
}

fn sum_complex(a: ComplexNumber, b: ComplexNumber) -> ComplexNumber {
  ComplexNumber(a.x + b.x, a.y + b.y)
}

fn multiply_complex(a: ComplexNumber, b: ComplexNumber) -> ComplexNumber {
  ComplexNumber(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)
}

fn divide_complex(a: ComplexNumber, b: ComplexNumber) -> ComplexNumber {
  ComplexNumber(a.x / b.x, a.y / b.y)
}

fn cycle(input: ComplexNumber, a: ComplexNumber) -> ComplexNumber {
  let i = multiply_complex(input, input)
  let j = divide_complex(i, ComplexNumber(10, 10))
  sum_complex(j, a)
}

fn cycles2(input: ComplexNumber, a: ComplexNumber, iterations: Int) -> Bool {
  case iterations {
    0 -> True
    _ -> {
      let i = multiply_complex(input, input)
      let j = divide_complex(i, ComplexNumber(100_000, 100_000))
      let k = sum_complex(j, a)
      let terminate =
        int.absolute_value(k.x) > 1_000_000
        || int.absolute_value(k.y) > 1_000_000
      case terminate {
        True -> False
        False -> cycles2(k, a, iterations - 1)
      }
    }
  }
}

fn parse_input(s: String) -> ComplexNumber {
  let assert Ok(re) = regexp.from_string("([+-]?\\d+),([+-]?\\d+)")
  let matches = regexp.scan(re, s)
  let result = case matches {
    [regexp.Match(content: _, submatches: [Some(x_str), Some(y_str)])] -> {
      let assert Ok(x) = int.parse(x_str)
      let assert Ok(y) = int.parse(y_str)
      ComplexNumber(x, y)
    }
    _ -> panic as "Invalid input format"
  }
  result
}

fn part1() -> String {
  let assert [a_str, ..] = util.read_input_lines(2, 1)
  let a = parse_input(a_str)
  let result = ComplexNumber(0, 0) |> cycle(a) |> cycle(a) |> cycle(a)
  "[" <> int.to_string(result.x) <> "," <> int.to_string(result.y) <> "]"
}

fn part2() -> String {
  let assert [a_str, ..] = util.read_input_lines(2, 2)
  let a = parse_input(a_str)
  let results =
    util.strided_range(a.x, a.x + 1000, 10)
    |> list.map(fn(row) {
      util.strided_range(a.y, a.y + 1000, 10)
      |> list.map(fn(col) {
        cycles2(ComplexNumber(0, 0), ComplexNumber(row, col), 100)
      })
    })

  let true_count =
    results |> list.flatten |> list.filter(fn(x) { x }) |> list.length
  int.to_string(true_count)
}

fn part3() -> String {
  let assert [a_str, ..] = util.read_input_lines(2, 3)
  let a = parse_input(a_str)
  let results =
    util.strided_range(a.x, a.x + 1000, 1)
    |> parallel_map.list_pmap(
      fn(row) {
        util.strided_range(a.y, a.y + 1000, 1)
        |> list.map(fn(col) {
          cycles2(ComplexNumber(0, 0), ComplexNumber(row, col), 100)
        })
      },
      MatchSchedulersOnline,
      100,
    )
    |> list.map(result.unwrap(_, []))

  let true_count =
    results |> list.flatten |> list.filter(fn(x) { x }) |> list.length
  int.to_string(true_count)
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
