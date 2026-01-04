import gleam/int
import gleam/list
import gleam/string
import gleam/yielder
import grid
import util

fn p1(numbers: List(Int), current: Int, acc: Int) -> Int {
  case current {
    0 -> acc
    _ -> {
      let curr_result =
        numbers
        |> list.fold(0, fn(iacc, x) {
          case current % x {
            0 -> iacc + 1
            _ -> iacc
          }
        })
      p1(numbers, current - 1, acc + curr_result)
    }
  }
}

fn p2(numbers: grid.Grid, idx: Int, acc: List(Int)) -> List(Int) {
  case idx >= numbers.cols {
    True -> acc |> list.reverse
    False -> {
      case grid.get(numbers, 0, idx) == 0 {
        True -> p2(numbers, idx + 1, acc)
        False -> {
          let ngrid =
            yielder.iterate(idx, fn(n) { n + idx })
            |> yielder.take_while(fn(n) { n < numbers.cols })
            |> yielder.fold(numbers, fn(acc, jdx) {
              let curr = grid.get(acc, 0, jdx)
              grid.set(acc, 0, jdx, curr - 1)
            })
          let nacc = [idx, ..acc]
          p2(ngrid, idx + 1, nacc)
        }
      }
    }
  }
}

fn binary_seach(
  lower: Int,
  upper: Int,
  numbers: List(Int),
  target: Int,
  result: Int,
) -> Int {
  case lower > upper {
    True -> result
    False -> {
      let mid = { lower + upper } / 2
      let mid_value =
        numbers
        |> list.fold(0, fn(acc, x) {
          let v = mid / x
          acc + v
        })
      case mid_value {
        v if v <= target -> binary_seach(mid + 1, upper, numbers, target, mid)
        v if v > target -> binary_seach(lower, mid - 1, numbers, target, result)
        _ -> panic as "Unreachable"
      }
    }
  }
}

fn parse(part: Int) -> List(Int) {
  let assert [input] = util.read_input_lines(16, part)
  let numbers =
    input
    |> string.split(",")
    |> list.map(fn(s) {
      let assert Ok(n) = int.parse(s)
      n
    })
  numbers
}

fn find_components(numbers: List(Int)) -> List(Int) {
  let grid_init = grid.create_grid(1, { numbers |> list.length } + 1)
  let numbers_grid =
    list.index_fold(numbers, grid_init, fn(acc, n, i) {
      grid.set(acc, 0, i + 1, n)
    })
  p2(numbers_grid, 1, [])
}

fn part1() -> String {
  let numbers = parse(1)
  let res = p1(numbers, 90, 0)
  res |> int.to_string
}

fn part2() -> String {
  let numbers = parse(2)
  let components = find_components(numbers)
  components
  |> list.fold(1, fn(a, b) { a * b })
  |> int.to_string
}

fn part3() -> String {
  let numbers = parse(3)
  let target = 202_520_252_025_000
  let components = find_components(numbers)
  let res = binary_seach(1, target, components, target, 0)
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
