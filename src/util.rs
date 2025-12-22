use std::path::PathBuf;

pub fn read_input(quest: u32, part: u32) -> String {
    let path = PathBuf::from(format!("data/quest{:02}_{}.txt", quest, part));
    std::fs::read_to_string(path).expect("Failed to read input file")
}

pub fn read_lines(quest: u32, part: u32) -> Vec<String> {
    let input = read_input(quest, part);
    input.lines().map(|line| line.to_string()).collect()
}

pub fn wrap_index<T>(index: T, len: T) -> T
where
    T: std::ops::Rem<Output = T> + std::ops::Add<Output = T> + Copy,
{
    ((index % len) + len) % len
}
