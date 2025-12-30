import gleam/int
import gleam/list
import gleam/string
import gleam/yielder
import grid.{type Grid}
import util

fn get_indexes(input: List(String), target: String) -> List(Int) {
  input
  |> list.index_fold([], fn(acc, x, index) {
    case x {
      _ if x == target -> [index, ..acc]
      _ -> acc
    }
  })
}

fn greedy_pairing(tutors: List(Int), students: List(Int)) -> Int {
  tutors
  |> list.map(fn(tutor_index) {
    students
    |> list.filter(fn(student_indx) { student_indx > tutor_index })
    |> list.length
  })
  |> list.reduce(fn(acc, x) { acc + x })
  |> util.force_unwrap
}

fn part1() -> String {
  let input =
    util.read_input_lines(6, 1)
    |> list.first
    |> util.force_unwrap
    |> string.to_graphemes
  let tutors = get_indexes(input, "A")
  let students = get_indexes(input, "a")
  let res = greedy_pairing(tutors, students)
  int.to_string(res)
}

fn part2() -> String {
  let input =
    util.read_input_lines(6, 2)
    |> list.first
    |> util.force_unwrap
    |> string.to_graphemes
  let pairs = [#("A", "a"), #("B", "b"), #("C", "c")]
  let res =
    pairs
    |> list.map(fn(pair) {
      let tutors = get_indexes(input, pair.0)
      let students = get_indexes(input, pair.1)
      greedy_pairing(tutors, students)
    })
    |> list.reduce(fn(acc, x) { acc + x })
    |> util.force_unwrap
  int.to_string(res)
}

fn get_valid(grid: Grid, pos: Int, repeats: Int, max_distance: Int) -> Int {
  let target = grid.get(grid, 0, pos) + 1
  let steps =
    yielder.iterate(1, fn(x) { x + 1 })
    |> yielder.take(max_distance)
  let left =
    steps
    |> yielder.fold(0, fn(acc, step) {
      let target_pos = pos - step
      let wrapped_pos = util.wrap_index(target_pos, grid.cols)
      case grid.get(grid, 0, wrapped_pos) {
        v if v == target -> {
          let offset = case target_pos < 0 {
            True -> { { -target_pos - 1 } / grid.cols } + 1
            False -> 0
          }
          acc + repeats - offset
        }
        _ -> acc
      }
    })
  let right =
    steps
    |> yielder.fold(0, fn(acc, step) {
      let target_pos = pos + step
      let wrapped_pos = util.wrap_index(target_pos, grid.cols)
      case grid.get(grid, 0, wrapped_pos) {
        v if v == target -> {
          let offset = case target_pos >= grid.cols {
            True -> target_pos / grid.cols
            False -> 0
          }
          acc + repeats - offset
        }
        _ -> acc
      }
    })
  left + right
}

fn part3() -> String {
  let input =
    util.read_input_lines(6, 3)
    |> list.first
    |> util.force_unwrap
    |> string.to_graphemes
  let char_grid =
    input
    |> list.index_fold(
      grid.create_grid(1, list.length(input)),
      fn(acc, x, index) {
        let value = case x {
          "a" -> 1
          "A" -> 2
          "b" -> 3
          "B" -> 4
          "c" -> 5
          "C" -> 6
          _ -> 0
        }
        grid.set(acc, 0, index, value)
      },
    )
  let repeats = 1000
  let limit = 1000
  let res =
    input
    |> list.index_fold(0, fn(acc, val, index) {
      case val {
        x if x == "a" || x == "b" || x == "c" -> {
          let valid = get_valid(char_grid, index, repeats, limit)
          acc + valid
        }
        _ -> acc
      }
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
