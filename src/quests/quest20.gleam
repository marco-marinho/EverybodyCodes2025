import gleam/dict
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/set
import gleam/string
import gleamy/priority_queue as pq
import util

type Coord3D {
  Coord3D(x: Int, y: Int, z: Int)
}

type Node {
  Node(position: Coord3D, cost: Int)
}

type Triangle {
  TypeA(x: Int, y: Int, z: Int, contents: Int)
  TypeB(x: Int, y: Int, z: Int, contents: Int)
}

fn rotate(triangle: Triangle, n: Int) -> Triangle {
  let coord = Coord3D(triangle.x, triangle.y, triangle.z)
  let new_coord = Coord3D(coord.y, coord.z + n, coord.x - n)
  case triangle {
    TypeA(_, _, _, contents) ->
      TypeA(new_coord.x, new_coord.y, new_coord.z, contents)
    TypeB(_, _, _, contents) ->
      TypeB(new_coord.x, new_coord.y, new_coord.z, contents)
  }
}

fn get_neighbours(triangle: Triangle) -> List(Coord3D) {
  case triangle {
    TypeA(x, y, z, _) -> [
      Coord3D(x, y, z),
      Coord3D(x + 1, y, z),
      Coord3D(x, y + 1, z),
      Coord3D(x, y, z + 1),
    ]
    TypeB(x, y, z, _) -> [
      Coord3D(x, y, z),
      Coord3D(x - 1, y, z),
      Coord3D(x, y - 1, z),
      Coord3D(x, y, z - 1),
    ]
  }
}

fn compare_nodes(a: Node, b: Node) -> Order {
  int.compare(a.cost, b.cost)
}

fn get_right(triangle: Triangle, value: Int) -> Triangle {
  case triangle {
    TypeA(x, y, z, _) -> TypeB(x + 1, y, z, value)
    TypeB(x, y, z, _) -> TypeA(x, y, z - 1, value)
  }
}

fn parse_lines(line: String, idx: Int) -> List(Triangle) {
  let line_chars = line |> string.replace(".", "") |> string.to_graphemes
  let first_char = line_chars |> list.first |> util.force_unwrap
  let other_chars = line_chars |> list.drop(1)
  let first_value = case first_char {
    "T" -> 1
    "S" -> 2
    "E" -> 3
    _ -> 0
  }
  let first_triangle = TypeB(0, idx, -idx, first_value)
  let other_triangles =
    other_chars
    |> list.scan(first_triangle, fn(acc, ch) {
      let value = case ch {
        "T" -> 1
        "S" -> 2
        "E" -> 3
        _ -> 0
      }
      get_right(acc, value)
    })
  [first_triangle, ..other_triangles]
}

fn count_neighbours(
  triangle_grid: dict.Dict(Coord3D, Triangle),
  pos: Coord3D,
) -> Int {
  let assert Ok(triangle) = dict.get(triangle_grid, pos)
  let res =
    get_neighbours(triangle)
    |> list.map(fn(coord) {
      case dict.get(triangle_grid, coord) {
        Ok(t) -> {
          case t.contents {
            0 -> 0
            _ -> 1
          }
        }
        Error(_) -> 0
      }
    })
    |> list.fold(0, fn(acc, x) { acc + x })
  res
}

fn djkistras(
  queue: pq.Queue(Node),
  seen: set.Set(Coord3D),
  grid: dict.Dict(Coord3D, Triangle),
  target_point: Coord3D,
  n: Int,
) -> Int {
  case pq.is_empty(queue) {
    True -> -1
    False -> {
      let assert Ok(#(current, nqueue)) = pq.pop(queue)
      let reached_goal = current.position == target_point
      let been_here = set.contains(seen, current.position)
      let curr_triangle = dict.get(grid, current.position)
      case reached_goal, been_here, curr_triangle {
        True, _, _ -> current.cost
        _, True, _ -> djkistras(nqueue, seen, grid, target_point, n)
        _, _, Error(_) -> djkistras(nqueue, seen, grid, target_point, n)
        _, _, Ok(curr_triangle) -> {
          let rotated = case n {
            0 -> curr_triangle
            _ -> rotate(curr_triangle, n)
          }
          let neighbors = rotated |> get_neighbours
          let filtered_neighbors =
            neighbors
            |> list.filter(fn(p) {
              !set.contains(seen, p)
              && dict.has_key(grid, p)
              && {
                dict.get(grid, p)
                |> util.force_unwrap
                |> fn(t) { t.contents != 0 }
              }
            })
          let updated_queue =
            filtered_neighbors
            |> list.fold(nqueue, fn(acc, p) {
              pq.push(acc, Node(p, current.cost + 1))
            })
          djkistras(
            updated_queue,
            set.insert(seen, current.position),
            grid,
            target_point,
            n,
          )
        }
      }
    }
  }
}

fn parse(part) -> dict.Dict(Coord3D, Triangle) {
  let input = util.read_input_lines(20, part)
  let triangles =
    input
    |> list.index_map(fn(line, idx) { parse_lines(line, idx) })
  let triangle_grid =
    triangles
    |> list.flatten
    |> list.map(fn(t) {
      let coord = Coord3D(t.x, t.y, t.z)
      #(coord, t)
    })
    |> dict.from_list()
  triangle_grid
}

fn get_start_end(
  triangle_grid: dict.Dict(Coord3D, Triangle),
) -> #(Coord3D, Coord3D) {
  let start_point =
    triangle_grid
    |> dict.values
    |> list.find(fn(t) { t.contents == 2 })
    |> util.force_unwrap
    |> fn(t) { Coord3D(t.x, t.y, t.z) }
  let end_point =
    triangle_grid
    |> dict.values
    |> list.find(fn(t) { t.contents == 3 })
    |> util.force_unwrap
    |> fn(t) { Coord3D(t.x, t.y, t.z) }
  #(start_point, end_point)
}

fn part1() -> String {
  let triangle_grid = parse(1)
  let valid =
    triangle_grid
    |> dict.values
    |> list.filter(fn(t) { t.contents != 0 })
  let neighbour_counts =
    valid
    |> list.map(fn(t) {
      count_neighbours(triangle_grid, Coord3D(t.x, t.y, t.z))
    })
  let res =
    neighbour_counts
    |> list.fold(0, fn(acc, x) { acc + x })
  { res / 2 } |> int.to_string
}

fn part2() -> String {
  let triangle_grid = parse(2)
  let #(start_point, end_point) = get_start_end(triangle_grid)
  let start_queue =
    pq.from_list(
      [Node(Coord3D(start_point.x, start_point.y, start_point.z), 0)],
      compare_nodes,
    )
  let res = djkistras(start_queue, set.new(), triangle_grid, end_point, 0)
  res |> int.to_string
}

fn part3() -> String {
  let triangle_grid = parse(3)
  let #(start_point, end_point) = get_start_end(triangle_grid)
  let n =
    triangle_grid
    |> dict.keys
    |> list.map(fn(c) { c.x })
    |> list.reduce(int.max)
    |> util.force_unwrap
  let start_queue =
    pq.from_list(
      [Node(Coord3D(start_point.x, start_point.y, start_point.z), 0)],
      compare_nodes,
    )
  let res = djkistras(start_queue, set.new(), triangle_grid, end_point, n)
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
