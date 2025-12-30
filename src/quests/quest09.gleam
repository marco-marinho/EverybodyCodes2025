import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import rslib_ffi
import util

type DNARecord {
  DNARecord(sequences: dict.Dict(Int, String), size: Int)
}

fn parse_line(line: String) -> String {
  let assert [_, dna] = string.split(line, ":")
  dna
}

fn calc_similarity(dna1: String, dna2: String) -> Int {
  let pairs = list.zip(dna1 |> string.to_graphemes, dna2 |> string.to_graphemes)
  list.fold(pairs, 0, fn(acc, chromosomes) {
    let #(c1, c2) = chromosomes
    case c1 == c2 {
      True -> acc + 1
      False -> acc
    }
  })
}

fn test_paternity(
  record: DNARecord,
  idx_child: Int,
  idx_p1: Int,
  idx_p2: Int,
) -> Bool {
  let chars1 =
    dict.get(record.sequences, idx_p1)
    |> util.force_unwrap
    |> string.to_graphemes
  let chars2 =
    dict.get(record.sequences, idx_p2)
    |> util.force_unwrap
    |> string.to_graphemes
  let chars_child =
    dict.get(record.sequences, idx_child)
    |> util.force_unwrap
    |> string.to_graphemes
  let matches =
    list.zip(chars_child, list.zip(chars1, chars2))
    |> list.all(fn(triples) {
      let #(c, #(p1, p2)) = triples
      case p1 == p2 {
        True -> c == p1
        False -> p1 == c || p2 == c
      }
    })
  matches
}

fn gen_search_indexes(
  idx: Int,
  size: Int,
  known_children: set.Set(Int),
) -> List(#(Int, Int, Int)) {
  let indexes =
    {
      use x <- list.flat_map(list.range(1, size))
      use y <- list.map(list.range(1, size))
      #(idx, x, y)
    }
    |> list.filter(fn(triple) {
      let #(i, x, y) = triple
      i != x
      && i != y
      && x < y
      && !set.contains(known_children, x)
      && !set.contains(known_children, y)
    })
  indexes
}

fn find_parents(
  record: DNARecord,
  idx_child: Int,
  known_children: set.Set(Int),
) -> Result(#(Int, Int, Int), Nil) {
  let size = record.size
  let indexes = gen_search_indexes(idx_child, size, known_children)
  let res =
    indexes
    |> list.find_map(fn(triple) {
      let #(i, x, y) = triple
      case test_paternity(record, i, x, y) {
        True -> Ok(#(idx_child, x, y))
        False -> Error(Nil)
      }
    })
  res
}

fn part1() -> String {
  let assert [a, b, c] = util.read_input_lines(9, 1) |> list.map(parse_line)
  let parents = [a, b]
  let scores = list.map(parents, fn(parent) { calc_similarity(parent, c) })
  let res = scores |> list.reduce(fn(acc, x) { acc * x }) |> util.force_unwrap
  res |> int.to_string
}

fn part2() -> String {
  rslib_ffi.rato()
  let sequences =
    util.read_input_lines(9, 2)
    |> list.index_fold(dict.new(), fn(acc, line, idx) {
      let dna = parse_line(line)
      dict.insert(acc, idx + 1, dna)
    })
  let dna_record = DNARecord(sequences, dict.size(sequences))
  let #(_, connections) =
    list.range(1, dna_record.size)
    |> list.map_fold(set.new(), fn(known_children, idx) {
      case find_parents(dna_record, idx, known_children) {
        Ok(#(child, p1, p2)) -> {
          let updated_children = set.insert(known_children, child)
          #(updated_children, Ok(#(child, p1, p2)))
        }
        Error(_) -> #(known_children, Error(Nil))
      }
    })

  connections
  |> list.filter(result.is_ok)
  |> list.map(util.force_unwrap)
  |> list.map(fn(triple) {
    let #(child, p1, p2) = triple
    let s1 =
      calc_similarity(
        dict.get(dna_record.sequences, child) |> util.force_unwrap,
        dict.get(dna_record.sequences, p1) |> util.force_unwrap,
      )
    let s2 =
      calc_similarity(
        dict.get(dna_record.sequences, child) |> util.force_unwrap,
        dict.get(dna_record.sequences, p2) |> util.force_unwrap,
      )
    s1 * s2
  })
  |> list.reduce(fn(acc, x) { acc + x })
  |> util.force_unwrap
  |> int.to_string
}

fn part3() -> String {
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
