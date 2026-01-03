import atomics_ffi
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder

pub type Grid {
  Grid(data: atomics_ffi.Atomics, rows: Int, cols: Int)
}

pub fn create_grid(rows: Int, cols: Int) -> Grid {
  let data = atomics_ffi.new(rows * cols, [atomics_ffi.Signed(True)])
  Grid(data, rows, cols)
}

pub fn set(grid: Grid, row: Int, col: Int, value: Int) -> Grid {
  let index = { row * grid.cols } + col + 1
  atomics_ffi.put(grid.data, index, value)
  grid
}

pub fn get(grid: Grid, row: Int, col: Int) -> Int {
  let index = { row * grid.cols } + col + 1
  atomics_ffi.get(grid.data, index)
}

pub fn to_string(grid: Grid) -> String {
  list.range(0, grid.rows - 1)
  |> list.map(fn(row) {
    list.range(0, grid.cols - 1)
    |> list.map(fn(col) { get(grid, row, col) |> int.to_string })
    |> string.join(", ")
  })
  |> string.join("\n")
}

pub fn to_hash(grid: Grid) -> Int {
  list.range(0, grid.rows - 1)
  |> list.fold(0, fn(acc, row) {
    list.range(0, grid.cols - 1)
    |> list.fold(acc, fn(acc2, col) {
      let val = get(grid, row, col)
      int.bitwise_shift_left(acc2, 1) + val
    })
  })
}

fn line_to_string(val: Int, acc: String, left: Int) -> String {
  case left {
    0 -> acc
    _ -> {
      let char = case val % 2 {
        1 -> "#"
        _ -> "."
      }
      line_to_string(int.bitwise_shift_right(val, 1), char <> acc, left - 1)
    }
  }
}

pub fn print_binary_grid(igrid: Grid, size: Int) {
  let lines =
    yielder.range(0, igrid.cols - 1)
    |> yielder.map(fn(idx) {
      let val = get(igrid, 0, idx)
      line_to_string(val, "", size)
    })
  yielder.each(lines, fn(line) { io.println(line) })
}
