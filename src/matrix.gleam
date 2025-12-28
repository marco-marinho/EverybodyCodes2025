import gleam/dict
import gleam/list
import gleam/string

pub type Matrix(a) {
  Matrix(rows: Int, cols: Int, data: dict.Dict(Int, a), default: a)
}

pub fn new(rows: Int, cols: Int, default: a) -> Matrix(a) {
  Matrix(rows, cols, dict.new(), default)
}

pub fn set(matrix: Matrix(a), row: Int, col: Int, value: a) -> Matrix(a) {
  let index = row * matrix.cols + col
  Matrix(..matrix, data: dict.insert(matrix.data, index, value))
}

pub fn get(matrix: Matrix(a), row: Int, col: Int) -> a {
  let index = row * matrix.cols + col
  case dict.get(matrix.data, index) {
    Ok(value) -> value
    Error(_) -> matrix.default
  }
}

pub fn check_bounds(matrix: Matrix(a), row: Int, col: Int) -> Bool {
  row >= 0 && row < matrix.rows && col >= 0 && col < matrix.cols
}

pub fn to_string(matrix: Matrix(a), format_element: fn(a) -> String) -> String {
  list.range(0, matrix.rows - 1)
  |> list.map(fn(row) {
    list.range(0, matrix.cols - 1)
    |> list.map(fn(col) { get(matrix, row, col) |> format_element })
    |> string.join(", ")
  })
  |> string.join("\n")
}
