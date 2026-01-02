import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import gleam/yielder
import grid
import util

fn evolve(current_grid: grid.Grid) -> #(grid.Grid, Int) {
  yielder.range(1, current_grid.rows - 2)
  |> yielder.fold(
    #(grid.create_grid(current_grid.rows, current_grid.cols), 0),
    fn(acc, row) {
      yielder.range(1, current_grid.cols - 2)
      |> yielder.fold(acc, fn(acc2, col) {
        let #(next_grid, current_active) = acc2
        let val = grid.get(current_grid, row, col)
        let active =
          grid.get(current_grid, row - 1, col - 1)
          + grid.get(current_grid, row + 1, col + 1)
          + grid.get(current_grid, row + 1, col - 1)
          + grid.get(current_grid, row - 1, col + 1)
        case val, active {
          1, x if x % 2 == 0 -> #(
            grid.set(next_grid, row, col, 0),
            current_active,
          )
          1, _ -> #(grid.set(next_grid, row, col, 1), current_active + 1)
          0, x if x % 2 == 0 -> #(
            grid.set(next_grid, row, col, 1),
            current_active + 1,
          )
          0, _ -> #(grid.set(next_grid, row, col, 0), current_active)
          _, _ -> panic as "Unreachable"
        }
      })
    },
  )
}

fn part1() -> String {
  let input = util.read_input_lines(14, 1)
  let rows = list.length(input)
  let cols = input |> list.first() |> util.force_unwrap |> string.length
  let grid_init = grid.create_grid(rows + 2, cols + 2)
  let curr_grid = {
    use acc, line, row <- list.index_fold(input, grid_init)
    use acc2, char, col <- list.index_fold(line |> string.to_graphemes, acc)
    case char {
      "#" -> grid.set(acc2, row + 1, col + 1, 1)
      _ -> acc2
    }
  }
  let #(_, final_active_counts) =
    list.range(1, 10)
    |> list.fold(#(curr_grid, 0), fn(acc, _) {
      let #(grid_so_far, active_counts) = acc
      let #(next_grid, active) = evolve(grid_so_far)
      #(next_grid, active_counts + active)
    })
  final_active_counts |> string.inspect
}

fn part2() -> String {
  let input = util.read_input_lines(14, 2)
  let rows = list.length(input)
  let cols = input |> list.first() |> util.force_unwrap |> string.length
  let grid_init = grid.create_grid(rows + 2, cols + 2)
  let curr_grid = {
    use acc, line, row <- list.index_fold(input, grid_init)
    use acc2, char, col <- list.index_fold(line |> string.to_graphemes, acc)
    case char {
      "#" -> grid.set(acc2, row + 1, col + 1, 1)
      _ -> acc2
    }
  }
  let #(_, final_active_counts) =
    list.range(1, 2025)
    |> list.fold(#(curr_grid, 0), fn(acc, _) {
      let #(grid_so_far, active_counts) = acc
      let #(next_grid, active) = evolve(grid_so_far)
      #(next_grid, active_counts + active)
    })
  final_active_counts |> string.inspect
}

fn find_cyle(a_grid: grid.Grid, a: Int, seen: set.Set(Int)) -> Int {
  let #(next_grid, _) = evolve(a_grid)
  case set.contains(seen, next_grid |> grid.to_hash) {
    True -> a
    _ ->
      find_cyle(next_grid, a + 1, set.insert(seen, next_grid |> grid.to_hash))
  }
}

fn part3() -> String {
  let grid_init = grid.create_grid(34 + 2, 34 + 2)
  find_cyle(grid_init, 0, set.new()) |> int.to_string
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
