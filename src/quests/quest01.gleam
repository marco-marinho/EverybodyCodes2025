import gleam/int
import gleam/list
import gleam/string
import grid
import util

type Command {
  Left(steps: Int)
  Right(steps: Int)
}

fn track_saturated(current: Int, max: Int, command: Command) -> Int {
  case command {
    Left(steps) -> {
      int.max(current - steps, 0)
    }
    Right(steps) -> {
      int.min(current + steps, max)
    }
  }
}

fn track_wrapping(current: Int, size: Int, command: Command) -> Int {
  case command {
    Left(steps) -> {
      util.wrap_index(current - steps, size)
    }
    Right(steps) -> {
      util.wrap_index(current + steps, size)
    }
  }
}

fn track_grid(current: grid.Grid, size: Int, command: Command) -> grid.Grid {
  let swap_idx = case command {
    Left(steps) -> {
      util.wrap_index(-steps, size)
    }
    Right(steps) -> {
      util.wrap_index(steps, size)
    }
  }
  let at_0 = grid.get(current, 0, 0)
  let at_swap = grid.get(current, 0, swap_idx)
  current |> grid.set(0, 0, at_swap) |> grid.set(0, swap_idx, at_0)
}

fn parse_command(command_str: String) -> Command {
  let direction = command_str |> string.slice(0, 1)
  let assert Ok(steps) =
    command_str |> string.slice(1, string.length(command_str)) |> int.parse
  case direction {
    "L" -> Left(steps)
    "R" -> Right(steps)
    _ -> panic as "Invalid command direction"
  }
}

fn part1() -> String {
  let assert [names_str, _, commands_str] = util.read_input_lines(1, 1)
  let names = string.split(names_str, ",")
  let num_names = list.length(names)
  let commands = string.split(commands_str, ",") |> list.map(parse_command)
  let final_idx =
    commands
    |> list.fold(0, fn(position, command) {
      track_saturated(position, num_names - 1, command)
    })
  let assert Ok(result) = names |> list.drop(final_idx) |> list.first
  result
}

fn part2() -> String {
  let assert [names_str, _, commands_str] = util.read_input_lines(1, 2)
  let names = string.split(names_str, ",")
  let num_names = list.length(names)
  let commands = string.split(commands_str, ",") |> list.map(parse_command)
  let final_idx =
    commands
    |> list.fold(0, fn(position, command) {
      track_wrapping(position, num_names, command)
    })
  let assert Ok(result) = names |> list.drop(final_idx) |> list.first
  result
}

fn part3() -> String {
  let assert [names_str, _, commands_str] = util.read_input_lines(1, 3)
  let names = string.split(names_str, ",")
  let num_names = list.length(names)
  let commands = string.split(commands_str, ",") |> list.map(parse_command)
  let idx_grid =
    list.range(0, num_names - 1)
    |> list.fold(grid.create_grid(1, num_names), fn(acc, idx) {
      grid.set(acc, 0, idx, idx)
    })
  let final_grid =
    commands
    |> list.fold(idx_grid, fn(current_grid, command) {
      track_grid(current_grid, num_names, command)
    })
  let final_idx = grid.get(final_grid, 0, 0)
  let assert Ok(result) = names |> list.drop(final_idx) |> list.first
  result
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
