import gleam/int
import gleam/list
import gleam/string
import gleam/yielder
import util

type Trace {
  Trace(a: Int, b: Int)
}

fn pos_mod(x: Int, n: Int) -> Int {
  { x % n + n } % n
}

fn has_knot(p1: Trace, p2: Trace, n: Int) -> Bool {
  let b_a = pos_mod(p1.b - p1.a, n)
  let i_a = pos_mod(p2.a - p1.a, n)
  let i_b = pos_mod(p2.b - p1.a, n)
  let first_inside = i_a > 0 && i_a < b_a
  let second_inside = i_b > 0 && i_b < b_a
  let one_in = first_inside != second_inside
  let b_a = pos_mod(p1.a - p1.b, n)
  let i_a = pos_mod(p2.a - p1.b, n)
  let i_b = pos_mod(p2.b - p1.b, n)
  let first_inside = i_a > 0 && i_a < b_a
  let second_inside = i_b > 0 && i_b < b_a
  let two_in = first_inside != second_inside
  one_in && two_in
}

fn part1() -> String {
  let input = util.read_input_lines(8, 1)
  let numbers =
    input
    |> list.first
    |> util.force_unwrap
    |> string.split(",")
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let half_len = 32 / 2
  let res =
    numbers
    |> list.window(2)
    |> list.fold(0, fn(acc, pair) {
      let assert [from, to] = pair
      case int.absolute_value(to - from) {
        x if x == half_len -> acc + 1
        _ -> acc
      }
    })
  int.to_string(res)
}

fn part2() -> String {
  let input = util.read_input_lines(8, 2)
  let numbers =
    input
    |> list.first
    |> util.force_unwrap
    |> string.split(",")
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let traces =
    numbers
    |> list.window(2)
    |> list.map(fn(pair) {
      let assert [from, to] = pair
      Trace(from, to)
    })
  let #(_, knots) =
    traces
    |> list.fold(#([], 0), fn(acc, trace) {
      let #(existing_traces, knot_count) = acc
      let new_knots =
        existing_traces
        |> list.filter(fn(existing) { has_knot(existing, trace, 256) })
        |> list.length
      #([trace, ..existing_traces], knot_count + new_knots)
    })
  knots |> int.to_string
}

fn count_knots(traces: List(Trace), cut: Trace, n: Int) -> Int {
  traces
  |> list.filter(fn(trace_b) {
    has_knot(trace_b, cut, n) || { cut.a == trace_b.a && cut.b == trace_b.b }
  })
  |> list.length
}

fn part3() -> String {
  let input = util.read_input_lines(8, 3)
  let n = 256
  let numbers =
    input
    |> list.first
    |> util.force_unwrap
    |> string.split(",")
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let traces =
    numbers
    |> list.window(2)
    |> list.map(fn(pair) {
      let assert [from, to] = pair
      case from < to {
        True -> Trace(from, to)
        False -> Trace(to, from)
      }
    })
  let res =
    yielder.iterate(1, fn(x) { x + 1 })
    |> yielder.take(n)
    |> yielder.fold(0, fn(acc, start) {
      yielder.iterate(start + 1, fn(x) { x + 1 })
      |> yielder.take_while(fn(x) { x <= n })
      |> yielder.fold(acc, fn(acc2, end) {
        int.max(acc2, count_knots(traces, Trace(start, end), n))
      })
    })
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
