import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import gleam/string
import gleam/yielder
import grid
import util

fn parse_line_bits(line: String) -> Int {
  line
  |> string.to_graphemes
  |> list.fold(0, fn(acc, char) {
    case char {
      "#" -> int.bitwise_shift_left(acc, 1) + 1
      _ -> int.bitwise_shift_left(acc, 1)
    }
  })
}

fn parse(part: Int) -> #(grid.Grid, Int) {
  let input = util.read_input_lines(14, part)
  let n_chars = input |> list.first() |> util.force_unwrap |> string.length
  let numbers = input |> list.map(parse_line_bits)
  let grid_init = grid.create_grid(1, list.length(numbers) + 2)
  let grid_res =
    numbers
    |> list.index_fold(grid_init, fn(acc, num, col) {
      grid.set(acc, 0, col + 1, num)
    })
  #(grid_res, n_chars)
}

fn evolve(current: grid.Grid, mask: Int) -> grid.Grid {
  yielder.range(1, current.cols - 2)
  |> yielder.fold(grid.create_grid(1, current.cols), fn(acc, col) {
    let prev = grid.get(current, 0, col - 1)
    let next = grid.get(current, 0, col + 1)
    let combined = int.bitwise_exclusive_or(prev, next)
    let odd_even =
      int.bitwise_exclusive_or(
        int.bitwise_shift_right(combined, 1),
        int.bitwise_shift_left(combined, 1),
      )
    let current = grid.get(current, 0, col)
    let next =
      int.bitwise_not(int.bitwise_exclusive_or(current, odd_even))
      |> int.bitwise_and(mask)
    grid.set(acc, 0, col, next)
  })
}

fn count_active(igrid: grid.Grid) -> Int {
  yielder.range(1, igrid.cols - 2)
  |> yielder.fold(0, fn(acc, col) {
    acc + util.count_set_bits(grid.get(igrid, 0, col))
  })
}

fn do_round(current: grid.Grid, mask: Int) -> #(grid.Grid, Int) {
  let next_grid = evolve(current, mask)
  let active_count = count_active(next_grid)
  #(next_grid, active_count)
}

fn make_mask(bits: Int) -> Int {
  int.bitwise_shift_left(1, bits) - 1
}

fn get_center(grid: grid.Grid) -> grid.Grid {
  let mask = make_mask(8)
  yielder.range(14, 21)
  |> yielder.fold(grid.create_grid(1, 8), fn(acc, col) {
    let original_val = grid.get(grid, 0, col)
    let maked_val =
      int.bitwise_shift_right(original_val, 13)
      |> int.bitwise_and(mask)
    grid.set(acc, 0, col - 14, maked_val)
  })
}

fn find_cycle(
  current_grid: grid.Grid,
  mask: Int,
  target: grid.Grid,
  detected: dict.Dict(Int, Int),
  seen: set.Set(Int),
  step: Int,
) -> #(Int, dict.Dict(Int, Int)) {
  let #(next_grid, _) = do_round(current_grid, mask)
  let grid_hash =
    yielder.range(1, next_grid.cols - 1)
    |> yielder.fold(0, fn(acc, col) {
      int.bitwise_shift_left(acc, 32) + grid.get(next_grid, 0, col)
    })
  let center = get_center(next_grid)
  let has_desired =
    yielder.range(0, 7)
    |> yielder.all(fn(idx) {
      grid.get(center, 0, idx) == grid.get(target, 0, idx + 1)
    })
  let next_detected = case has_desired {
    True -> dict.insert(detected, step, count_active(next_grid))
    False -> detected
  }
  case set.contains(seen, grid_hash) {
    True -> #(step - 1, next_detected)
    False ->
      find_cycle(
        next_grid,
        mask,
        target,
        next_detected,
        set.insert(seen, grid_hash),
        step + 1,
      )
  }
}

fn part1() -> String {
  let #(curr_grid, n_chars) = parse(1)
  let #(_, final_active_counts) =
    list.range(1, 10)
    |> list.fold(#(curr_grid, 0), fn(acc, _) {
      let #(grid_so_far, active_counts) = acc
      let #(next_grid, active) = do_round(grid_so_far, make_mask(n_chars))
      #(next_grid, active_counts + active)
    })
  final_active_counts |> string.inspect
}

fn part2() -> String {
  let #(curr_grid, n_chars) = parse(2)
  let #(_, final_active_counts) =
    list.range(1, 2025)
    |> list.fold(#(curr_grid, 0), fn(acc, _) {
      let #(grid_so_far, active_counts) = acc
      let #(next_grid, active) = do_round(grid_so_far, make_mask(n_chars))
      #(next_grid, active_counts + active)
    })
  final_active_counts |> string.inspect
}

fn part3() -> String {
  let target_rounds = 1_000_000_000
  let #(target, _) = parse(3)
  let curr_grid = grid.create_grid(1, 36)
  let n_chars = 34
  let mask = make_mask(n_chars)
  let #(cycle, detected) =
    find_cycle(curr_grid, mask, target, dict.new(), set.new(), 1)
  let num_complete_cycles = target_rounds / cycle
  let remaining = target_rounds % cycle
  let total_complete =
    {
      dict.values(detected)
      |> list.fold(0, fn(acc, val) { acc + val })
    }
    * num_complete_cycles
  let total_remaining =
    detected
    |> dict.filter(fn(key, _) { key < remaining })
    |> dict.values
    |> list.fold(0, fn(acc, val) { acc + val })
  { total_complete + total_remaining } |> string.inspect
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
