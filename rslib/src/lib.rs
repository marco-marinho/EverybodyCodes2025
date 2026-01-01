use std::collections::HashSet;
use std::collections::VecDeque;
use std::fs;

pub fn quest10_1_helper(start_pos: (i64, i64), boundaries: (i64, i64)) -> HashSet<(i64, i64)> {
    let moves = [
        (-2, -1),
        (-2, 1),
        (-1, -2),
        (-1, 2),
        (1, -2),
        (1, 2),
        (2, -1),
        (2, 1),
    ];
    let mut visited: HashSet<(i64, i64)> = HashSet::new();
    let mut queue: VecDeque<(i64, i64)> = vec![start_pos].into();
    let mut iteration = 0;
    while !queue.is_empty() {
        let mut next_queue: VecDeque<(i64, i64)> = VecDeque::new();
        while !queue.is_empty() {
            let (r, c) = queue.pop_front().unwrap();
            if visited.contains(&(r, c)) {
                continue;
            }
            visited.insert((r, c));
            for (dr, dc) in moves.iter() {
                let new_pos = (r + dr, c + dc);
                if new_pos.0 < 0
                    || new_pos.0 >= boundaries.0
                    || new_pos.1 < 0
                    || new_pos.1 >= boundaries.1
                {
                    continue;
                }
                if !visited.contains(&new_pos) {
                    next_queue.push_back(new_pos);
                }
            }
        }
        queue = next_queue;
        iteration += 1;
        if iteration == 5 {
            break;
        }
    }
    visited
}

#[rustler::nif]
pub fn quest10_1() -> String {
    let input = fs::read_to_string("data/quest10_1.txt").unwrap_or("".to_string());
    let sheeps: HashSet<(i64, i64)> = input
        .lines()
        .enumerate()
        .flat_map(|(r, line)| {
            line.chars()
                .enumerate()
                .filter_map(move |(c, ch)| (ch == 'S').then_some((r as i64, c as i64)))
        })
        .collect();
    let rows = input.lines().count() as i64;
    let cols = input.lines().next().map_or(0, |l| l.len()) as i64;
    let start_pos = (rows / 2, cols / 2);
    let visited = quest10_1_helper(start_pos, (rows, cols));
    let intersection_size = sheeps.intersection(&visited).count();
    intersection_size.to_string()
}

rustler::init!("librs");
