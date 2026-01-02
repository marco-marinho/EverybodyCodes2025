import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import util

type Range {
  Range(start: Int, end: Int, size: Int, reverse: Bool)
}

fn line_to_range(line: String, reverse: Bool) -> Range {
  let parts = string.split(line, "-")
  let assert Ok(start_str) = list.first(parts)
  let assert Ok(end_str) = list.drop(parts, 1) |> list.first
  let assert Ok(start) = start_str |> int.parse
  let assert Ok(end) = end_str |> int.parse
  Range(start, end, end - start + 1, reverse)
}

fn find_number(
  ranges: dict.Dict(Int, Range),
  current_idx: Int,
  left: Int,
) -> Int {
  let current_range = dict.get(ranges, current_idx) |> util.force_unwrap
  case left {
    x if x < current_range.size ->
      case current_range.reverse {
        False -> current_range.start + left
        True -> current_range.end - left
      }
    _ -> find_number(ranges, current_idx + 1, left - current_range.size)
  }
}

fn solution(input: List(String), target_index: Int) -> String {
  let ranges =
    input |> list.index_map(fn(x, i) { line_to_range(x, i % 2 == 0) })
  let num_ranges = list.length(ranges)
  let ranges_grid = {
    use acc, val, idx <- list.index_fold(ranges, dict.new())
    case idx {
      0 -> dict.insert(acc, 0, val)
      x if x % 2 == 1 -> {
        let idx_to_set = { idx + 1 } / 2
        dict.insert(acc, idx_to_set, val)
      }
      _ -> {
        let idx_to_set = util.wrap_index(-idx / 2, num_ranges)
        dict.insert(acc, idx_to_set, val)
      }
    }
  }
  let total_size = ranges |> list.fold(0, fn(acc, r) { acc + r.size })
  let final_point = util.wrap_index(target_index, total_size)
  let ans = find_number(ranges_grid, 0, final_point)
  ans |> string.inspect
}

fn part1() -> String {
  let input =
    ["1", ..util.read_input_lines(13, 1)]
    |> list.map(fn(x) { x <> "-" <> x })
  let ans = solution(input, 2025)
  ans
}

fn part2() -> String {
  let input = ["1-1", ..util.read_input_lines(13, 2)]
  let ans = solution(input, 20_252_025)
  ans
}

fn part3() -> String {
  let input = ["1-1", ..util.read_input_lines(13, 3)]
  let ans = solution(input, 202_520_252_025)
  ans
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
