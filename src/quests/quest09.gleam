import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glearray
import grid
import parallel_map.{MatchSchedulersOnline}
import util

type DNARecord {
  DNARecord(
    sequences: glearray.Array(Int),
    original_sequence: glearray.Array(String),
    size: Int,
  )
}

type UnionFind {
  UnionFind(parents: grid.Grid, sizes: grid.Grid)
}

fn new_union_find(size: Int) -> UnionFind {
  let uf_grid =
    list.range(0, size)
    |> list.fold(grid.create_grid(1, size + 1), fn(acc, i) {
      grid.set(acc, 0, i, i)
    })
  let size_grid =
    list.range(1, size)
    |> list.fold(grid.create_grid(1, size + 1), fn(acc, i) {
      grid.set(acc, 0, i, 1)
    })
  UnionFind(uf_grid, size_grid)
}

fn find(uf: UnionFind, i: Int) -> #(Int, UnionFind) {
  let parent = grid.get(uf.parents, 0, i)
  case parent {
    x if x == i -> #(i, uf)
    _ -> {
      let #(new_parent, new_uf) = find(uf, parent)
      let updated_parents = grid.set(new_uf.parents, 0, i, new_parent)
      #(new_parent, UnionFind(..new_uf, parents: updated_parents))
    }
  }
}

fn union(uf: UnionFind, i: Int, j: Int) -> UnionFind {
  let #(root_i, curr_uf) = find(uf, i)
  let #(root_j, curr_uf) = find(curr_uf, j)
  case root_i == root_j {
    True -> curr_uf
    False -> {
      case
        grid.get(curr_uf.sizes, 0, root_i),
        grid.get(curr_uf.sizes, 0, root_j)
      {
        x, y if x >= y -> {
          let new_sizes = grid.set(curr_uf.sizes, 0, root_i, x + y)
          let new_parents = grid.set(curr_uf.parents, 0, root_j, root_i)
          UnionFind(sizes: new_sizes, parents: new_parents)
        }
        x, y -> {
          let new_sizes = grid.set(curr_uf.sizes, 0, root_j, x + y)
          let new_parents = grid.set(curr_uf.parents, 0, root_i, root_j)
          UnionFind(sizes: new_sizes, parents: new_parents)
        }
      }
    }
  }
}

fn parse_line(line: String) -> String {
  let assert [_, dna] = string.split(line, ":")
  dna
}

fn to_bits(dna: String) -> Int {
  case dna {
    "A" -> 0
    "C" -> 1
    "G" -> 2
    "T" -> 3
    _ -> panic as "Invalid DNA character"
  }
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
  let c =
    glearray.get(record.sequences, idx_child)
    |> util.force_unwrap
  let p1 =
    glearray.get(record.sequences, idx_p1)
    |> util.force_unwrap
  let p2 =
    glearray.get(record.sequences, idx_p2)
    |> util.force_unwrap
  let pc1 = int.bitwise_exclusive_or(p1, c)
  let pc2 = int.bitwise_exclusive_or(p2, c)
  let test_result = int.bitwise_and(pc1, pc2)
  test_result == 0
}

fn find_parents(
  x: Int,
  y: Int,
  record: DNARecord,
  idx_child: Int,
) -> Result(#(Int, Int, Int), Nil) {
  case x, y {
    i, _ if i == idx_child -> find_parents(x + 1, 1, record, idx_child)
    _, j if j == idx_child -> find_parents(x, y + 1, record, idx_child)
    i, _ if i > record.size -> Error(Nil)
    _, j if j > record.size -> find_parents(x + 1, 1, record, idx_child)
    _, _ -> {
      case test_paternity(record, idx_child, x, y) {
        True -> Ok(#(idx_child, x, y))
        False -> find_parents(x, y + 1, record, idx_child)
      }
    }
  }
}

fn build_records(part: Int) -> DNARecord {
  let #(sequences, original_sequences) =
    util.read_input_lines(9, part)
    |> list.fold(#([0], [""]), fn(acc, line) {
      let dna_str = parse_line(line)
      let dna =
        dna_str
        |> string.to_graphemes
        |> list.fold(0, fn(acc, c) {
          let value = to_bits(c)
          int.bitwise_or(int.bitwise_shift_left(acc, 2), value)
        })
      #([dna, ..acc.0], [dna_str, ..acc.1])
    })
  DNARecord(
    glearray.from_list(list.reverse(sequences)),
    glearray.from_list(list.reverse(original_sequences)),
    list.length(sequences) - 1,
  )
}

fn find_connections(record: DNARecord) -> List(#(Int, Int, Int)) {
  list.range(1, record.size)
  |> parallel_map.list_pmap(
    fn(idx) {
      case find_parents(1, 1, record, idx) {
        Ok(#(child, p1, p2)) -> {
          Ok(#(child, p1, p2))
        }
        Error(_) -> Error(Nil)
      }
    },
    MatchSchedulersOnline,
    300,
  )
  |> list.map(util.force_unwrap)
  |> list.filter(result.is_ok)
  |> list.map(util.force_unwrap)
}

fn part1() -> String {
  let assert [a, b, c] = util.read_input_lines(9, 1) |> list.map(parse_line)
  let parents = [a, b]
  let scores = list.map(parents, fn(parent) { calc_similarity(parent, c) })
  let res = scores |> list.reduce(fn(acc, x) { acc * x }) |> util.force_unwrap
  res |> int.to_string
}

fn part2() -> String {
  let dna_record = build_records(2)
  let connections = find_connections(dna_record)
  let similarities =
    connections
    |> list.map(fn(triple) {
      let #(c, p1, p2) = triple
      let sim1 =
        calc_similarity(
          glearray.get(dna_record.original_sequence, p1)
            |> util.force_unwrap,
          glearray.get(dna_record.original_sequence, c)
            |> util.force_unwrap,
        )
      let sim2 =
        calc_similarity(
          glearray.get(dna_record.original_sequence, p2)
            |> util.force_unwrap,
          glearray.get(dna_record.original_sequence, c)
            |> util.force_unwrap,
        )
      sim1 * sim2
    })
  similarities
  |> list.reduce(fn(acc, x) { acc + x })
  |> util.force_unwrap
  |> int.to_string
}

fn part3() -> String {
  let dna_record = build_records(3)
  let connections = find_connections(dna_record)
  let uf =
    connections
    |> list.fold(new_union_find(dna_record.size), fn(acc, triple) {
      let #(c, p1, p2) = triple
      let acc1 = union(acc, c, p1)
      union(acc1, c, p2)
    })
  let #(max_idx, _) =
    list.range(1, dna_record.size)
    |> list.fold(#(0, 0), fn(acc, i) {
      let #(_, curr_max) = acc
      let i_size = grid.get(uf.sizes, 0, i)
      case i_size > curr_max {
        True -> #(i, i_size)
        False -> acc
      }
    })
  let res =
    list.range(1, dna_record.size)
    |> list.fold(0, fn(acc, i) {
      let #(parent, _) = find(uf, i)
      case parent == max_idx {
        True -> acc + i
        False -> acc
      }
    })
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
