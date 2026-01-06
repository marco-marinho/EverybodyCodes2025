import argv
import gleam/int
import gleam/io
import quests/quest01
import quests/quest02
import quests/quest03
import quests/quest04
import quests/quest05
import quests/quest06
import quests/quest07
import quests/quest08
import quests/quest09
import quests/quest10
import quests/quest11
import quests/quest12
import quests/quest13
import quests/quest14
import quests/quest15
import quests/quest16
import quests/quest17
import quests/quest18
import quests/quest19

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
    3 -> quest03.solve(part)
    4 -> quest04.solve(part)
    5 -> quest05.solve(part)
    6 -> quest06.solve(part)
    7 -> quest07.solve(part)
    8 -> quest08.solve(part)
    9 -> quest09.solve(part)
    10 -> quest10.solve(part)
    11 -> quest11.solve(part)
    12 -> quest12.solve(part)
    13 -> quest13.solve(part)
    14 -> quest14.solve(part)
    15 -> quest15.solve(part)
    16 -> quest16.solve(part)
    17 -> quest17.solve(part)
    18 -> quest18.solve(part)
    19 -> quest19.solve(part)
    _ -> "Quest not implemented"
  }
  result |> io.println
}
