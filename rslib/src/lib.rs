use std::collections::HashSet;
use std::collections::VecDeque;
use std::fs;
use std::vec;

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

fn to_int_grid(input: &str) -> Vec<Vec<i64>> {
    input
        .lines()
        .map(|line| {
            line.chars()
                .map(|ch| ch.to_digit(10).unwrap_or(0) as i64)
                .collect()
        })
        .collect()
}

fn q12_1(start: Vec<(usize, usize)>, grid: &Vec<Vec<i64>>) -> usize {
    let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    let rows = grid.len() as i64;
    let cols = grid[0].len() as i64;
    let mut queue: VecDeque<(usize, usize)> = start.into();
    let mut visited: HashSet<(usize, usize)> = HashSet::new();
    while !queue.is_empty() {
        let mut next_queue: VecDeque<(usize, usize)> = VecDeque::new();
        while !queue.is_empty() {
            let (r, c) = queue.pop_front().unwrap();
            if visited.contains(&(r, c)) {
                continue;
            }
            visited.insert((r, c));
            let current_height = grid[r][c];
            for (dr, dc) in directions.iter() {
                let new_r = r as i64 + dr;
                let new_c = c as i64 + dc;
                if new_r < 0 || new_r >= rows || new_c < 0 || new_c >= cols {
                    continue;
                }
                let new_r_usize = new_r as usize;
                let new_c_usize = new_c as usize;
                let new_height = grid[new_r_usize][new_c_usize];
                if new_height <= current_height {
                    next_queue.push_back((new_r_usize, new_c_usize));
                }
            }
        }
        queue = next_queue;
    }
    visited.len()
}

#[rustler::nif]
pub fn quest12_1() -> String {
    let input = fs::read_to_string("data/quest12_1.txt").unwrap_or("".to_string());
    let grid = to_int_grid(&input);
    let res = q12_1(vec![(0, 0)], &grid);
    res.to_string()
}

#[rustler::nif]
pub fn quest12_2() -> String {
    let input = fs::read_to_string("data/quest12_2.txt").unwrap_or("".to_string());
    let grid = to_int_grid(&input);
    let rows = grid.len();
    let cols = grid[0].len();
    let res = q12_1(vec![(0, 0), (rows - 1, cols - 1)], &grid);
    res.to_string()
}

rustler::init!("librs");
