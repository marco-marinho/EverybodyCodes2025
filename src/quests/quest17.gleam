import cppnif_ffi
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/result
import gleam/string
import gleam/yielder
import gleamy/priority_queue as pq
import grid
import matrix
import util

type Point {
  Point(x: Int, y: Int)
}

type Node {
  Node(position: Point, cost: Int)
}

type Side {
  Left
  Right
}

fn compare_nodes(a: Node, b: Node) -> Order {
  int.compare(a.cost, b.cost)
}

fn make_unvisitable(
  rows: Int,
  cols: Int,
  mouth: Point,
  start: Point,
  radius: Int,
  side: Side,
) -> grid.Grid {
  let grid_init = grid.create_grid(rows, cols)
  let unvisitable = {
    let row_range = yielder.range(0, rows - 1)
    let col_range = yielder.range(0, cols - 1)
    use acc, row <- yielder.fold(row_range, grid_init)
    use acc2, col <- yielder.fold(col_range, acc)
    let dist =
      { row - mouth.x }
      * { row - mouth.x }
      + { col - mouth.y }
      * { col - mouth.y }
    let mid_grid = case dist <= radius * radius {
      True -> grid.set(acc2, row, col, 1)
      False -> acc2
    }
    let updated_grid = case side {
      Left ->
        case col > mouth.y && row > start.x {
          True -> grid.set(mid_grid, row, col, 1)
          False -> mid_grid
        }
      Right ->
        case col < mouth.y && row > start.x {
          True -> grid.set(mid_grid, row, col, 1)
          False -> mid_grid
        }
    }
    updated_grid
  }
  unvisitable
}

fn djkistras(
  queue: pq.Queue(Node),
  unvisitable: grid.Grid,
  board: grid.Grid,
  target_point: Point,
) -> Int {
  case pq.is_empty(queue) {
    True -> -1
    False -> {
      let assert Ok(#(curr_node, curr_queue)) = pq.pop(queue)
      let reached_goal = curr_node.position == target_point
      let been_here =
        grid.get(unvisitable, curr_node.position.x, curr_node.position.y) == 1
      case reached_goal, been_here {
        True, _ -> curr_node.cost
        _, True -> djkistras(curr_queue, unvisitable, board, target_point)
        _, _ -> {
          let neighbors =
            [
              Point(curr_node.position.x - 1, curr_node.position.y),
              Point(curr_node.position.x + 1, curr_node.position.y),
              Point(curr_node.position.x, curr_node.position.y - 1),
              Point(curr_node.position.x, curr_node.position.y + 1),
            ]
            |> list.filter(fn(p) {
              p.x >= 0
              && p.y >= 0
              && p.x < board.rows
              && p.y < board.cols
              && grid.get(unvisitable, p.x, p.y) == 0
            })
          let updated_queue =
            neighbors
            |> list.fold(curr_queue, fn(acc, p) {
              let cost = grid.get(board, p.x, p.y)
              pq.push(acc, Node(p, curr_node.cost + cost))
            })
          let updated_grid =
            grid.set(unvisitable, curr_node.position.x, curr_node.position.y, 1)
          djkistras(updated_queue, updated_grid, board, target_point)
        }
      }
    }
  }
}

fn check_possible(
  cost_grid: grid.Grid,
  mouth: Point,
  start_end: Point,
  radius: Int,
) -> Result(Int, Nil) {
  let unvisitable =
    make_unvisitable(
      cost_grid.rows,
      cost_grid.cols,
      mouth,
      start_end,
      radius,
      Left,
    )
  let mid_point = Point(mouth.x + radius + 1, mouth.y)
  let to_cost =
    djkistras(
      pq.from_list([Node(start_end, 0)], compare_nodes),
      unvisitable,
      cost_grid,
      mid_point,
    )
  case to_cost >= { radius + 1 } * 30 {
    True -> Error(Nil)
    False -> {
      let unvisitable =
        make_unvisitable(
          cost_grid.rows,
          cost_grid.cols,
          mouth,
          start_end,
          radius,
          Right,
        )
      let from_cost =
        djkistras(
          pq.from_list([Node(mid_point, 0)], compare_nodes),
          unvisitable,
          cost_grid,
          start_end,
        )
      case to_cost + from_cost >= { radius + 1 } * 30 {
        True -> Error(Nil)
        False -> Ok(to_cost + from_cost)
      }
    }
  }
}

fn part1() -> String {
  let res = cppnif_ffi.q17_1()
  res
}

fn part2() -> String {
  let res = cppnif_ffi.q17_2()
  res
}

fn part3() -> String {
  let input = util.read_input_lines(17, 3)
  let char_matrix =
    matrix.from_list(input |> list.map(string.to_graphemes), "#")
  let numbers =
    list.map(input, fn(line) {
      line
      |> string.to_graphemes
      |> list.map(fn(c) { int.parse(c) |> result.unwrap(0) })
    })
  let cost_grid = grid.from_list(numbers)
  let assert Ok([start]) = matrix.find(char_matrix, "S")
  let assert Ok([mouth]) = matrix.find(char_matrix, "@")
  let mouth_point = Point(mouth.0, mouth.1)
  let start_point = Point(start.0, start.1)
  let res =
    yielder.range(0, cost_grid.rows / 2)
    |> yielder.find_map(fn(radius) {
      let possible = check_possible(cost_grid, mouth_point, start_point, radius)
      case possible {
        Error(_) -> Error(Nil)
        Ok(cost) -> Ok(cost * radius)
      }
    })
  res |> util.force_unwrap |> int.to_string
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
