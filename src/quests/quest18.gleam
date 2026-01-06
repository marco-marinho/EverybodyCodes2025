import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import glearray
import util

type Connection {
  Connection(to: Int, thickness: Int)
}

type Plant {
  Plant(id: Int, thickness: Int, connections: List(Connection))
}

type RootResult =
  #(dict.Dict(Int, Int), Int)

type PlantNetwork {
  PlantNetwork(end: Int, plants: dict.Dict(Int, Plant))
}

fn parse_branch(line: String) -> Connection {
  case line {
    "- free branch with thickness " <> thickness_str ->
      Connection(-1, util.force_unwrap(int.parse(thickness_str)))
    "- branch to Plant " <> rest -> {
      let assert [id, thicknes] =
        rest
        |> string.split(" with thickness ")
        |> list.map(int.parse)
        |> list.map(util.force_unwrap)
      Connection(id, thicknes)
    }
    _ -> panic as "Invalid branch line"
  }
}

fn parse_block(lines: List(String)) {
  let assert [h, ..t] = lines
  let assert [id, thickness] =
    h
    |> string.replace("Plant ", "")
    |> string.replace(":", "")
    |> string.split(" with thickness ")
    |> list.map(int.parse)
    |> list.map(util.force_unwrap)
  let connections = t |> list.map(parse_branch)
  Plant(id, thickness, connections)
}

fn parse_command(line: String) -> dict.Dict(Int, Int) {
  line
  |> string.split(" ")
  |> list.index_fold(dict.new(), fn(acc, x, idx) {
    case x {
      "1" -> dict.insert(acc, idx + 1, 1)
      "0" -> dict.insert(acc, idx + 1, 0)
      _ -> panic as "Invalid command"
    }
  })
}

fn eval_plant(
  plant_id: Int,
  plants: dict.Dict(Int, Plant),
  root_values: dict.Dict(Int, Int),
) -> Int {
  let assert Ok(plant) = dict.get(plants, plant_id)
  let connections_pwr =
    plant.connections
    |> list.map(fn(conn) {
      case conn.to {
        -1 -> dict.get(root_values, plant_id) |> util.force_unwrap
        id -> {
          let assert Ok(p) = dict.get(plants, id)
          eval_plant(p.id, plants, root_values) * conn.thickness
        }
      }
    })
    |> list.fold(0, fn(acc, x) { acc + x })
  case connections_pwr >= plant.thickness {
    True -> connections_pwr
    False -> 0
  }
}

fn get_best(iarray: glearray.Array(RootResult)) -> RootResult {
  list.range(0, glearray.length(iarray) - 1)
  |> list.fold(#(dict.new(), 0), fn(acc, idx) {
    let assert Ok(entry) = glearray.get(iarray, idx)
    let #(_, best) = acc
    let #(_, power) = entry
    case power > best {
      True -> entry
      False -> acc
    }
  })
}

fn tournament_round(population: glearray.Array(RootResult)) -> Int {
  let n = glearray.length(population)
  let #(winner_idx, _) =
    [
      int.random(n),
      int.random(n),
      int.random(n),
      int.random(n),
      int.random(n),
    ]
    |> list.fold(#(0, 0), fn(acc, idx) {
      let assert Ok(entry) = glearray.get(population, idx)
      let #(_, val) = entry
      let #(_, best_val) = acc
      case val > best_val {
        True -> #(idx, val)
        False -> acc
      }
    })
  winner_idx
}

fn crossover(
  parent1: RootResult,
  parent2: RootResult,
  network: PlantNetwork,
) -> RootResult {
  let #(roots1, _) = parent1
  let #(roots2, _) = parent2
  let new_roots =
    dict.keys(roots1)
    |> list.fold(dict.new(), fn(acc, key) {
      let val1 = dict.get(roots1, key) |> util.force_unwrap
      let val2 = dict.get(roots2, key) |> util.force_unwrap
      let chosen_val = case int.random(2) {
        0 -> val1
        _ -> val2
      }
      dict.insert(acc, key, chosen_val)
    })
  let to_mutate = int.random(dict.size(new_roots)) + 1
  let current_val = dict.get(new_roots, to_mutate) |> util.force_unwrap
  let new_roots = dict.insert(new_roots, to_mutate, 1 - current_val)
  let new_power = eval_plant(network.end, network.plants, new_roots)
  #(new_roots, new_power)
}

fn make_random(size: Int, network: PlantNetwork) -> RootResult {
  let roots =
    list.range(1, size)
    |> list.fold(dict.new(), fn(acc, key) {
      let val = int.random(2)
      dict.insert(acc, key, val)
    })
  let power = eval_plant(network.end, network.plants, roots)
  #(roots, power)
}

fn evolve(
  population: glearray.Array(RootResult),
  network: PlantNetwork,
) -> glearray.Array(RootResult) {
  let elite = get_best(population)
  let size = dict.size(elite.0)
  let parents =
    list.range(1, 20)
    |> list.map(fn(_) { tournament_round(population) })
  let pairs =
    parents
    |> list.combination_pairs
  let parent_results =
    parents
    |> list.map(fn(idx) { glearray.get(population, idx) |> util.force_unwrap })
  let children_results =
    pairs
    |> list.map(fn(pair) {
      let #(p1, p2) = pair
      crossover(
        glearray.get(population, p1) |> util.force_unwrap,
        glearray.get(population, p2) |> util.force_unwrap,
        network,
      )
    })
  let random_results =
    list.range(1, 50)
    |> list.map(fn(_) { make_random(size, network) })
  let res = [elite]
  let res = list.fold(parent_results, res, fn(acc, x) { [x, ..acc] })
  let res = list.fold(children_results, res, fn(acc, x) { [x, ..acc] })
  let res = list.fold(random_results, res, fn(acc, x) { [x, ..acc] })
  res |> glearray.from_list
}

fn part1() -> String {
  let input = util.read_input_lines(18, 1)
  let blocks = input |> util.split_on(fn(x) { x == "" })
  let plants =
    blocks
    |> list.map(parse_block)
    |> list.fold(dict.new(), fn(acc, plant) {
      dict.insert(acc, plant.id, plant)
    })
  let target_id =
    plants |> dict.keys |> list.reduce(int.max) |> util.force_unwrap
  let active_roots =
    list.range(1, dict.size(plants))
    |> list.map(fn(x) { #(x, 1) })
    |> dict.from_list
  let res = eval_plant(target_id, plants, active_roots)
  res |> string.inspect |> io.println

  ""
}

fn part2() -> String {
  let input = util.read_input_lines(18, 2)
  let blocks = input |> util.split_on(fn(x) { x == "" })
  let block_len = blocks |> list.length
  let plants_block = blocks |> list.take(block_len - 1)
  let commands_block = list.last(blocks) |> util.force_unwrap
  let plants =
    plants_block
    |> list.map(parse_block)
    |> list.fold(dict.new(), fn(acc, plant) {
      dict.insert(acc, plant.id, plant)
    })
  let target_id =
    plants |> dict.keys |> list.reduce(int.max) |> util.force_unwrap
  let command_roots = commands_block |> list.map(parse_command)
  let results =
    command_roots
    |> list.map(fn(active_roots) { eval_plant(target_id, plants, active_roots) })
  let res = results |> list.reduce(fn(a, b) { a + b }) |> util.force_unwrap
  res |> int.to_string
}

fn part3() -> String {
  let input = util.read_input_lines(18, 3)
  let blocks = input |> util.split_on(fn(x) { x == "" })
  let block_len = blocks |> list.length
  let plants_block = blocks |> list.take(block_len - 1)
  let commands_block = list.last(blocks) |> util.force_unwrap
  let plants =
    plants_block
    |> list.map(parse_block)
    |> list.fold(dict.new(), fn(acc, plant) {
      dict.insert(acc, plant.id, plant)
    })
  let target_id =
    plants |> dict.keys |> list.reduce(int.max) |> util.force_unwrap
  let command_roots = commands_block |> list.map(parse_command)
  let first_generation =
    command_roots
    |> list.map(fn(active_roots) {
      let result = eval_plant(target_id, plants, active_roots)
      #(active_roots, result)
    })
    |> glearray.from_list
  let network = PlantNetwork(target_id, plants)
  let final_population =
    list.range(1, 3)
    |> list.fold(first_generation, fn(population, _) {
      evolve(population, network)
    })
  let #(_, best_power) = get_best(final_population)
  let res =
    command_roots
    |> list.map(fn(active_roots) {
      let curr_res = eval_plant(target_id, plants, active_roots)
      case curr_res > 0 {
        True -> best_power - curr_res
        False -> 0
      }
    })
    |> list.fold(0, fn(acc, x) { acc + x })
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
