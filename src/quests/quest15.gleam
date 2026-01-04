import gleam/dict
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/set
import gleam/string
import gleam/yielder
import gleamy/priority_queue as pq
import glearray
import grid
import util

type Direction {
  North
  South
  East
  West
}

type Turn {
  Left
  Right
}

type Point {
  Point(x: Int, y: Int)
}

type State {
  State(position: Point, direction: Direction)
}

type Command {
  Command(turn: Turn, steps: Int)
}

type Node {
  Node(position: Point, cost: Int)
}

fn compare_nodes(a: Node, b: Node) -> Order {
  int.compare(a.cost, b.cost)
}

fn string_to_command(s: String) -> Command {
  let turn_char = string.slice(s, 0, 1)
  let steps_str = string.slice(s, 1, string.length(s))
  let turn = case turn_char {
    "L" -> Left
    "R" -> Right
    _ -> panic as "Invalid turn character"
  }
  let assert Ok(steps) = int.parse(steps_str)
  Command(turn, steps)
}

fn get_delta(dir: Direction) -> Point {
  case dir {
    North -> Point(-1, 0)
    South -> Point(1, 0)
    East -> Point(0, 1)
    West -> Point(0, -1)
  }
}

fn walk(commands: List(Command), state: State, acc: List(Point)) -> List(Point) {
  case commands {
    [] -> {
      acc |> list.reverse()
    }
    [Command(cturn, steps), ..tail] -> {
      let new_dir = turn(state.direction, cturn)
      let delta = get_delta(new_dir)
      let next_position =
        Point(
          state.position.x + { delta.x * steps },
          state.position.y + { delta.y * steps },
        )
      let new_acc = [next_position, ..acc]
      let new_state = State(next_position, new_dir)
      walk(tail, new_state, new_acc)
    }
  }
}

fn djkistras(
  queue: pq.Queue(Node),
  uncompressed_map: #(glearray.Array(Int), glearray.Array(Int)),
  seen: set.Set(Point),
  board: grid.Grid,
  target_point: Point,
) -> Int {
  case pq.is_empty(queue) {
    True -> -1
    False -> {
      let assert Ok(#(current, nqueue)) = pq.pop(queue)
      let reached_goal = current.position == target_point
      let been_here = set.contains(seen, current.position)
      case reached_goal, been_here {
        True, _ -> current.cost
        _, True ->
          djkistras(nqueue, uncompressed_map, seen, board, target_point)
        _, _ -> {
          let #(xs_array, ys_array) = uncompressed_map
          let assert Ok(curr_x_real) =
            glearray.get(xs_array, current.position.x)
          let assert Ok(curr_y_real) =
            glearray.get(ys_array, current.position.y)
          let neighbors =
            [
              Point(current.position.x - 1, current.position.y),
              Point(current.position.x + 1, current.position.y),
              Point(current.position.x, current.position.y - 1),
              Point(current.position.x, current.position.y + 1),
            ]
            |> list.filter(fn(p) {
              p.x >= 0
              && p.y >= 0
              && p.x < board.rows
              && p.y < board.cols
              && grid.get(board, p.x, p.y) == 0
              && !set.contains(seen, p)
            })
          let updated_queue =
            neighbors
            |> list.fold(nqueue, fn(acc, p) {
              let assert Ok(next_x_real) = glearray.get(xs_array, p.x)
              let assert Ok(next_y_real) = glearray.get(ys_array, p.y)
              let cost =
                int.absolute_value(next_x_real - curr_x_real)
                + int.absolute_value(next_y_real - curr_y_real)
              pq.push(acc, Node(p, current.cost + cost))
            })
          djkistras(
            updated_queue,
            uncompressed_map,
            set.insert(seen, current.position),
            board,
            target_point,
          )
        }
      }
    }
  }
}

fn turn(dir: Direction, t: Turn) -> Direction {
  case t {
    Left ->
      case dir {
        North -> West
        West -> South
        South -> East
        East -> North
      }
    Right ->
      case dir {
        North -> East
        East -> South
        South -> West
        West -> North
      }
  }
}

fn xs_ys(
  input: List(Point),
  acc: #(List(Int), List(Int)),
) -> #(List(Int), List(Int)) {
  case input {
    [] -> {
      let #(xs, ys) = acc
      let x_res = xs |> list.unique |> list.sort(int.compare)
      let y_res = ys |> list.unique |> list.sort(int.compare)
      #(x_res, y_res)
    }
    [Point(x, y), ..tail] -> {
      let #(xs, ys) = acc
      xs_ys(tail, #([x + 1, x, x - 1, ..xs], [y + 1, y, y - 1, ..ys]))
    }
  }
}

fn solution(part: Int) -> String {
  let assert [x] = util.read_input_lines(15, part)
  let commands =
    x
    |> string.split(",")
    |> list.map(string_to_command)
  let corners = walk(commands, State(Point(0, 0), North), [Point(0, 0)])
  let #(xs, ys) = xs_ys(corners, #([], []))
  let xs_map =
    xs
    |> list.index_fold(dict.new(), fn(acc, x, i) { dict.insert(acc, x, i) })
  let ys_map =
    ys
    |> list.index_fold(dict.new(), fn(acc, y, i) { dict.insert(acc, y, i) })
  let x_comp_to_real = glearray.from_list(xs)
  let y_comp_to_real = glearray.from_list(ys)
  let assert Ok(end_point) = corners |> list.last
  let compressed_grid = grid.create_grid(xs |> list.length, ys |> list.length)
  let filled_grid =
    corners
    |> list.window(2)
    |> list.fold(compressed_grid, fn(acc, pair) {
      let assert [start, end] = pair
      let assert Ok(start_x_grid) = dict.get(xs_map, start.x)
      let assert Ok(end_x_grid) = dict.get(xs_map, end.x)
      let assert Ok(start_y_grid) = dict.get(ys_map, start.y)
      let assert Ok(end_y_grid) = dict.get(ys_map, end.y)
      let new_acc = {
        let x_range = yielder.range(start_x_grid, end_x_grid)
        let y_range = yielder.range(start_y_grid, end_y_grid)
        use acc1, grid_x <- yielder.fold(x_range, acc)
        use acc2, grid_y <- yielder.fold(y_range, acc1)
        grid.set(acc2, grid_x, grid_y, 1)
      }
      new_acc
    })
  let assert Ok(x_comp_end) = dict.get(xs_map, end_point.x)
  let assert Ok(y_comp_end) = dict.get(ys_map, end_point.y)
  let assert Ok(x_comp_start) = dict.get(xs_map, 0)
  let assert Ok(y_comp_start) = dict.get(ys_map, 0)
  let filled_grid = grid.set(filled_grid, x_comp_end, y_comp_end, 0)
  let start_queue =
    pq.from_list([Node(Point(x_comp_start, y_comp_start), 0)], compare_nodes)
  let res =
    djkistras(
      start_queue,
      #(x_comp_to_real, y_comp_to_real),
      set.new(),
      filled_grid,
      Point(x_comp_end, y_comp_end),
    )
  res |> int.to_string
}

fn part1() -> String {
  solution(1)
}

fn part2() -> String {
  solution(2)
}

fn part3() -> String {
  solution(3)
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
