import gleam/dict
import gleam/list
import gleam/string
import util

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

pub fn find(matrix: Matrix(a), value: a) -> Result(List(#(Int, Int)), Nil) {
  let filtered = dict.filter(matrix.data, fn(_, v) { v == value })
  case dict.size(filtered) {
    0 -> Error(Nil)
    _ -> {
      let res =
        dict.to_list(filtered)
        |> list.map(fn(entry) {
          let #(index, _) = entry
          let row = index / matrix.cols
          let col = index % matrix.cols
          #(row, col)
        })
      Ok(res)
    }
  }
}

pub fn from_list(elements: List(List(a)), default: a) -> Matrix(a) {
  let rows = list.length(elements)
  let cols = list.first(elements) |> util.force_unwrap |> list.length
  let odict = {
    use acc, ilist, row <- list.index_fold(elements, dict.new())
    use acc2, el, col <- list.index_fold(ilist, acc)
    let index = row * rows + col
    dict.insert(acc2, index, el)
  }
  Matrix(rows, cols, odict, default)
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
