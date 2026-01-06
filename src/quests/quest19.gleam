import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import util

type Opening {
  Opening(position: Int, possibilities: List(Int))
}

type State {
  State(position: Int, height: Int)
}

type Memo =
  dict.Dict(State, Result(Int, Nil))

fn dfs(
  state: State,
  openings: List(Opening),
  memo: Memo,
) -> #(Result(Int, Nil), Memo) {
  let in_memo = dict.get(memo, state)
  case openings, in_memo {
    [], _ -> #(Ok(0), memo)
    _, Ok(cached) -> #(cached, memo)
    [h, ..t], _ -> {
      let dist_delta = h.position - state.position
      let heights_to_hit = h.possibilities
      let #(possible_costs, updated_memo) =
        heights_to_hit
        |> list.fold(#([], memo), fn(acc, to_hit) {
          let #(acc_costs, acc_memo) = acc
          let height_delta = to_hit - state.height
          let valid =
            { height_delta + dist_delta } % 2 == 0
            && int.absolute_value(height_delta) <= dist_delta
          case valid {
            False -> #([Error(Nil), ..acc_costs], acc_memo)
            True -> {
              let up_flapps = { height_delta + dist_delta } / 2
              let #(remaining, new_memo) =
                dfs(State(position: h.position, height: to_hit), t, acc_memo)
              case remaining {
                Error(_) -> #([Error(Nil), ..acc_costs], new_memo)
                Ok(v) -> #([Ok(up_flapps + v), ..acc_costs], new_memo)
              }
            }
          }
        })
      let valid_costs =
        possible_costs
        |> list.fold([], fn(acc, x) {
          case x {
            Ok(v) -> [v, ..acc]
            Error(_) -> acc
          }
        })
      let min_cost = case valid_costs {
        [] -> Error(Nil)
        _ -> Ok(list.reduce(valid_costs, int.min) |> util.force_unwrap)
      }
      let final_memo = dict.insert(updated_memo, state, min_cost)
      #(min_cost, final_memo)
    }
  }
}

fn parse_line(
  line: String,
  acc: dict.Dict(Int, List(Int)),
) -> dict.Dict(Int, List(Int)) {
  let parts = line |> string.split(",")
  let int_parts =
    parts
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let assert [pos, start, size] = int_parts
  let new_range = case dict.get(acc, pos) {
    Ok(existing) -> {
      list.range(start, start + size - 1)
      |> list.fold(existing, fn(acc, x) { [x, ..acc] })
    }
    Error(_) -> {
      list.range(start, start + size - 1)
    }
  }
  dict.insert(acc, pos, new_range)
}

fn opening_dict_to_list(
  openings_dict: dict.Dict(Int, List(Int)),
) -> List(Opening) {
  openings_dict
  |> dict.to_list()
  |> list.map(fn(entry) {
    let #(pos, possibilities) = entry
    Opening(position: pos, possibilities: possibilities)
  })
  |> list.sort(fn(a, b) { int.compare(a.position, b.position) })
}

fn part1() -> String {
  let input = util.read_input_lines(19, 1)
  let openings_dict =
    input
    |> list.fold(dict.new(), fn(acc, x) { parse_line(x, acc) })
  let openings = opening_dict_to_list(openings_dict)
  let #(res, _) = dfs(State(position: 0, height: 0), openings, dict.new())
  res |> util.force_unwrap |> string.inspect
}

fn part2() -> String {
  let input = util.read_input_lines(19, 2)
  let openings_dict =
    input
    |> list.fold(dict.new(), fn(acc, x) { parse_line(x, acc) })
  let openings = opening_dict_to_list(openings_dict)
  let #(res, _) = dfs(State(position: 0, height: 0), openings, dict.new())
  res |> util.force_unwrap |> string.inspect
}

fn part3() -> String {
  let input = util.read_input_lines(19, 3)
  let openings_dict =
    input
    |> list.fold(dict.new(), fn(acc, x) { parse_line(x, acc) })
  let openings = opening_dict_to_list(openings_dict)
  let #(res, _) = dfs(State(position: 0, height: 0), openings, dict.new())
  res |> util.force_unwrap |> string.inspect
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
