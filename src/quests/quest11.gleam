import gleam/int
import gleam/list
import util

fn forward_pass(input: List(Int), acc: List(Int)) -> List(Int) {
  case input {
    [a, b, ..rest] -> {
      case a > b {
        True -> forward_pass([b + 1, ..rest], [a - 1, ..acc])
        False -> forward_pass([b, ..rest], [a, ..acc])
      }
    }
    [a] -> list.reverse([a, ..acc])
    [] -> list.reverse(acc)
  }
}

fn backward_pass(input: List(Int), acc: List(Int)) -> List(Int) {
  case input {
    [a, b, ..rest] -> {
      case b > a {
        True -> backward_pass([b - 1, ..rest], [a + 1, ..acc])
        False -> backward_pass([b, ..rest], [a, ..acc])
      }
    }
    [a] -> list.reverse([a, ..acc])
    [] -> list.reverse(acc)
  }
}

fn foward_to_stable(input: List(Int), current: Int) -> #(List(Int), Int) {
  let next = forward_pass(input, [])
  case next == input {
    True -> #(next, current)
    False -> foward_to_stable(next, current + 1)
  }
}

fn backward_to_stable(input: List(Int), current: Int) -> #(List(Int), Int) {
  let next = backward_pass(input, [])
  case next == input {
    True -> #(next, current)
    False -> backward_to_stable(next, current + 1)
  }
}

fn backward_up_to(input: List(Int), left: Int) -> List(Int) {
  case left {
    0 -> input
    _ -> {
      let next = backward_pass(input, [])
      backward_up_to(next, left - 1)
    }
  }
}

fn part1() -> String {
  let input =
    util.read_input_lines(11, 1)
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let #(after_forward, rounds_taken) = foward_to_stable(input, 0)
  let after_backward = backward_up_to(after_forward, 10 - rounds_taken)
  let res =
    after_backward
    |> list.index_fold(0, fn(acc, x, idx) { acc + x * { idx + 1 } })
  res |> int.to_string
}

fn part2() -> String {
  let input =
    util.read_input_lines(11, 2)
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let #(after_forward, rounds_taken_forward) = foward_to_stable(input, 0)
  let #(_, rounds_taken_backward) = backward_to_stable(after_forward, 0)
  let res = rounds_taken_forward + rounds_taken_backward
  res |> int.to_string
}

fn part3() -> String {
  let input =
    util.read_input_lines(11, 3)
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let sum =
    input
    |> list.fold(0, fn(acc, x) { acc + x })
  let avg = sum / list.length(input)
  let res =
    input
    |> list.map(fn(x) {
      case x < avg {
        True -> avg - x
        False -> 0
      }
    })
    |> list.fold(0, fn(acc, x) { acc + x })
  res |> int.to_string
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
