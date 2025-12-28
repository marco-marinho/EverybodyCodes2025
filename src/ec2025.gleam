import argv
import gleam/int
import gleam/io
import quests/quest01
import quests/quest02

pub fn main() -> Nil {
  let args = argv.load().arguments
  let assert [quest, part] = case args {
    [quest_str, part_str] -> {
      let assert Ok(q) = int.parse(quest_str)
      let assert Ok(p) = int.parse(part_str)
      [q, p]
    }
    _ -> panic as "Please provide quest and part numbers as arguments"
  }
  let result = case quest {
    1 -> quest01.solve(part)
    2 -> quest02.solve(part)
    _ -> "Quest not implemented"
  }
  result |> io.println
}
