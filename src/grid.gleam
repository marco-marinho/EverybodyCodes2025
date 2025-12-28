import atomics_ffi
import gleam/int
import gleam/list
import gleam/string

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
