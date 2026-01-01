import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import rslib_ffi
import util

type Sheep {
  Sheep(row: Int, col: Int, id: Int)
}

type GridSize {
  GridSize(rows: Int, cols: Int)
}

type Turn {
  SheepTurn
  DragonTurn
}

type GameState {
  GameState(
    dragon: #(Int, Int),
    sheep: List(Sheep),
    turn: Turn,
    sheep_left: Int,
  )
}

fn chip_sheep(sheep: List(#(Int, Int))) -> List(Sheep) {
  sheep
  |> list.index_map(fn(x, i) {
    let #(r, c) = x
    Sheep(r, c, i)
  })
}

fn walk_sheep(sheep: List(Sheep), grid_size: GridSize) -> List(Sheep) {
  sheep
  |> list.map(fn(x) { Sheep(..x, row: x.row + 1) })
  |> list.filter(fn(x) { x.row < grid_size.rows })
}

fn walk_dragon(
  dragon: List(#(Int, Int)),
  grid_size: GridSize,
) -> List(#(Int, Int)) {
  dragon
  |> list.flat_map(fn(x) {
    let #(r, c) = x
    [
      #(r - 2, c - 1),
      #(r - 2, c + 1),
      #(r - 1, c - 2),
      #(r - 1, c + 2),
      #(r + 1, c - 2),
      #(r + 1, c + 2),
      #(r + 2, c - 1),
      #(r + 2, c + 1),
    ]
  })
  |> list.unique
  |> list.filter(fn(x) {
    let #(r, c) = x
    r >= 0 && c >= 0 && r < grid_size.rows && c < grid_size.cols
  })
}

fn eat_sheep(
  dragon: List(#(Int, Int)),
  sheep: List(Sheep),
  shelters: set.Set(#(Int, Int)),
) -> #(List(Sheep), Int) {
  let active_dragons =
    dragon
    |> list.filter(fn(x) { !set.contains(shelters, x) })
    |> set.from_list
  sheep
  |> list.fold(#([], 0), fn(acc, s) {
    let #(ss, nk) = acc
    let sheep_pos = #(s.row, s.col)
    case set.contains(active_dragons, sheep_pos) {
      True -> #(ss, nk + 1)
      False -> #([s, ..ss], nk)
    }
  })
}

fn do_turn(
  dragon: List(#(Int, Int)),
  sheep: List(Sheep),
  shelters: set.Set(#(Int, Int)),
  grid_size: GridSize,
) -> #(List(Sheep), Int) {
  let #(pre_turn, eaten_pre_turn) = eat_sheep(dragon, sheep, shelters)
  let #(post_turn, eaten_post_turn) =
    eat_sheep(dragon, walk_sheep(pre_turn, grid_size), shelters)
  #(post_turn, eaten_pre_turn + eaten_post_turn)
}

fn do_turn_2(
  game_state: GameState,
  shelters: set.Set(#(Int, Int)),
  grid_size: GridSize,
  memo: dict.Dict(GameState, Int),
) -> #(Int, dict.Dict(GameState, Int)) {
  case dict.get(memo, game_state) {
    Ok(cached) -> #(cached, memo)
    Error(_) -> {
      case game_state.sheep_left, game_state.turn {
        0, _ -> #(1, memo)
        _, SheepTurn -> {
          let #(res, omemo, moved) = {
            use #(s_acc, m_acc, c_acc), s <- list.fold(game_state.sheep, #(
              0,
              memo,
              False,
            ))
            let next_row = s.row + 1
            let is_shelter = set.contains(shelters, #(next_row, s.col))
            case next_row, s.col {
              n, m if game_state.dragon == #(n, m) && !is_shelter -> #(
                s_acc,
                m_acc,
                c_acc,
              )
              n, _ if n >= grid_size.rows -> #(s_acc, m_acc, True)
              n, _ -> {
                let next_sheep =
                  [
                    Sheep(..s, row: n),
                    ..list.filter(game_state.sheep, fn(x) { x.id != s.id })
                  ]
                  |> list.sort(fn(a, b) { int.compare(a.id, b.id) })
                let next_state =
                  GameState(
                    dragon: game_state.dragon,
                    sheep: next_sheep,
                    turn: DragonTurn,
                    sheep_left: game_state.sheep_left,
                  )
                let #(solutions, new_memo) =
                  do_turn_2(next_state, shelters, grid_size, m_acc)
                #(s_acc + solutions, new_memo, True)
              }
            }
          }
          case moved {
            True -> #(res, dict.insert(omemo, game_state, res))
            False -> {
              let next_state = GameState(..game_state, turn: DragonTurn)
              let #(res, new_memo) =
                do_turn_2(next_state, shelters, grid_size, memo)
              #(res, dict.insert(new_memo, game_state, res))
            }
          }
        }
        _, DragonTurn -> {
          let next_dragons = walk_dragon([game_state.dragon], grid_size)
          let #(res, omemo) =
            next_dragons
            |> list.fold(#(0, memo), fn(acc, d) {
              let #(sol_acc, curr_memo) = acc
              let eaten =
                game_state.sheep
                |> list.find_map(fn(s) {
                  case
                    s.row == d.0 && s.col == d.1 && !set.contains(shelters, d)
                  {
                    True -> Ok(s.id)
                    False -> Error(Nil)
                  }
                })
              let #(next_sheep, eaten_count) = case eaten {
                Ok(eaten_id) -> #(
                  list.filter(game_state.sheep, fn(x) { x.id != eaten_id })
                    |> list.sort(fn(a, b) { int.compare(a.id, b.id) }),
                  1,
                )
                Error(_) -> #(game_state.sheep, 0)
              }
              let next_state =
                GameState(
                  dragon: d,
                  sheep: next_sheep,
                  turn: SheepTurn,
                  sheep_left: game_state.sheep_left - eaten_count,
                )
              let #(solutions, new_memo) =
                do_turn_2(next_state, shelters, grid_size, curr_memo)
              #(sol_acc + solutions, new_memo)
            })
          #(res, dict.insert(omemo, game_state, res))
        }
      }
    }
  }
}

fn play(
  dragons: List(#(Int, Int)),
  sheep: List(Sheep),
  shelters: set.Set(#(Int, Int)),
  grid_size: GridSize,
  turns_left: Int,
  acc: Int,
) -> Int {
  case turns_left {
    0 -> acc
    _ -> {
      let next_dragons = walk_dragon(dragons, grid_size)
      let #(next_sheep, eaten) =
        do_turn(next_dragons, sheep, shelters, grid_size)
      play(
        next_dragons,
        next_sheep,
        shelters,
        grid_size,
        turns_left - 1,
        acc + eaten,
      )
    }
  }
}

fn parse(
  part: Int,
) -> #(List(Sheep), set.Set(#(Int, Int)), #(Int, Int), GridSize) {
  let input = util.read_input_lines(10, part)
  let rows = list.length(input)
  let cols = input |> list.first() |> util.force_unwrap |> string.length
  let grid_size = GridSize(rows, cols)
  let #(raw_sheep, shelters, raw_dragon) =
    input
    |> list.index_fold(#([], [], #(0, 0)), fn(acc, line, row) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(iacc, char, col) {
        let #(isheep, ishelters, idragon) = iacc
        case char {
          "#" -> #(isheep, [#(row, col), ..ishelters], idragon)
          "S" -> #([#(row, col), ..isheep], ishelters, idragon)
          "D" -> #(isheep, ishelters, #(row, col))
          _ -> iacc
        }
      })
    })
  let sheep = chip_sheep(raw_sheep |> list.reverse)
  #(sheep, set.from_list(shelters), raw_dragon, grid_size)
}

fn part1() -> String {
  let res = rslib_ffi.quest10_1()
  res
}

fn part2() -> String {
  let #(sheep, shelters, raw_dragon, grid_size) = parse(2)
  let res = play([raw_dragon], sheep, shelters, grid_size, 20, 0)
  res |> int.to_string |> io.println
  ""
}

fn part3() -> String {
  let #(sheep, shelters, raw_dragon, grid_size) = parse(3)
  let starting_state =
    GameState(
      dragon: raw_dragon,
      sheep: sheep,
      turn: SheepTurn,
      sheep_left: list.length(sheep),
    )
  let #(solutions, _) =
    do_turn_2(starting_state, shelters, grid_size, dict.new())
  solutions |> int.to_string |> io.println
  ""
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
