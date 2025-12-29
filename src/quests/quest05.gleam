import gleam/dict
import gleam/int
import gleam/list
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/string
import gleam/yielder
import util

type Fish =
  dict.Dict(#(Int, Int), Int)

type FishRecord {
  FishRecord(id: Int, fish: Fish, quality: Int)
}

fn assemble_fish(fish: Fish, numbers: List(Int)) -> Fish {
  list.fold(numbers, fish, fn(acc, n) { insert_number(acc, n) })
}

fn insert_number(fish: Fish, n: Int) -> Fish {
  yielder.unfold(0, fn(level) { yielder.Next(level, level + 1) })
  |> yielder.map(fn(level) {
    case dict.get(fish, #(level, 0)) {
      Error(_) -> Ok(dict.insert(fish, #(level, 0), n))
      Ok(x) if n > x -> {
        case dict.get(fish, #(level, 1)) {
          Error(_) -> Ok(dict.insert(fish, #(level, 1), n))
          Ok(_) -> Error(Nil)
        }
      }
      Ok(x) if n < x -> {
        case dict.get(fish, #(level, -1)) {
          Error(_) -> Ok(dict.insert(fish, #(level, -1), n))
          Ok(_) -> Error(Nil)
        }
      }
      _ -> Error(Nil)
    }
  })
  |> yielder.find(result.is_ok)
  |> result.flatten
  |> util.force_unwrap
}

fn get_quality(fish: Fish) -> String {
  yielder.unfold(0, fn(level) { yielder.Next(level, level + 1) })
  |> yielder.map(fn(level) { dict.get(fish, #(level, 0)) })
  |> yielder.take_while(result.is_ok)
  |> yielder.map(fn(res) {
    let assert Ok(res) = res
    int.to_string(res)
  })
  |> yielder.fold("", fn(acc, x) { acc <> x })
}

fn parse_line(line: String) -> List(Int) {
  line
  |> string.split(":")
  |> util.last
  |> string.split(",")
  |> list.map(int.parse)
  |> result.values
}

fn get_fish_quality(numbers: List(Int)) -> Int {
  let fish =
    dict.new()
    |> dict.insert(#(0, 0), numbers |> util.first)
  let fish = assemble_fish(fish, numbers |> list.drop(1))
  let quality = get_quality(fish)
  let assert Ok(res) = int.parse(quality)
  res
}

fn get_fish_level(fish: Fish, level: Int) -> Int {
  let left = case dict.get(fish, #(level, -1)) {
    Error(_) -> ""
    Ok(x) -> int.to_string(x)
  }
  let mid = case dict.get(fish, #(level, 0)) {
    Error(_) -> ""
    Ok(x) -> int.to_string(x)
  }
  let right = case dict.get(fish, #(level, 1)) {
    Error(_) -> ""
    Ok(x) -> int.to_string(x)
  }
  let num_str = left <> mid <> right
  int.parse(num_str) |> result.unwrap(0)
}

fn sort_fish(fish1: Fish, fish2: Fish) -> Order {
  yielder.unfold(0, fn(level) { yielder.Next(level, level + 1) })
  |> yielder.map(fn(level) {
    case get_fish_level(fish1, level), get_fish_level(fish2, level) {
      x, y if x < y -> Ok(Lt)
      x, y if x > y -> Ok(Gt)
      0, 0 -> Ok(Eq)
      _, _ -> Error(Nil)
    }
  })
  |> yielder.find(result.is_ok)
  |> result.flatten
  |> util.force_unwrap
}

fn sort_records(r1: FishRecord, r2: FishRecord) -> Order {
  case int.compare(r1.quality, r2.quality) {
    Lt -> Lt
    Gt -> Gt
    Eq ->
      case sort_fish(r1.fish, r2.fish) {
        Lt -> Lt
        Gt -> Gt
        Eq -> int.compare(r1.id, r2.id)
      }
  }
}

fn part1() -> String {
  let input = util.read_input_lines(5, 1)
  let numbers =
    util.first(input)
    |> parse_line
  let quality = get_fish_quality(numbers)
  int.to_string(quality)
}

fn part2() -> String {
  let input = util.read_input_lines(5, 2)
  let numbers = input |> list.map(parse_line)
  let qualities = numbers |> list.map(get_fish_quality)
  let assert Ok(max_quality) = qualities |> list.reduce(int.max)
  let assert Ok(min_quality) = qualities |> list.reduce(int.min)
  let difference = max_quality - min_quality
  int.to_string(difference)
}

fn part3() -> String {
  let input = util.read_input_lines(5, 3)
  let numbers = input |> list.map(parse_line)
  let fishes = numbers |> list.map(fn(x) { assemble_fish(dict.new(), x) })
  let qualities =
    fishes
    |> list.map(fn(x) { get_quality(x) })
    |> list.map(int.parse)
    |> result.values
  let records =
    list.zip(fishes, qualities)
    |> list.index_map(fn(x, i) { FishRecord(i + 1, x.0, x.1) })
  let sorted_ids =
    list.sort(records, sort_records) |> list.map(fn(x) { x.id }) |> list.reverse
  let assert Ok(res) =
    sorted_ids
    |> list.index_map(fn(x, i) { x * { i + 1 } })
    |> list.reduce(fn(acc, x) { acc + x })
  res |> string.inspect
}

pub fn solve(part: Int) -> String {
  case part {
    1 -> part1()
    2 -> part2()
    3 -> part3()
    _ -> "Invalid part"
  }
}
