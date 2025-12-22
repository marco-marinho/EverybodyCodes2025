use crate::util;

pub fn part1() {
    let lines = util::read_lines(1, 1);
    let names = lines[0].split(',').collect::<Vec<&str>>();
    let commands = lines[2].split(',').collect::<Vec<&str>>();
    let mut current = 0;
    for command in commands {
        let action = &command[0..1];
        let value: i32 = command[1..].parse().expect("Invalid number");
        let offset = match action {
            "R" => value,
            "L" => -value,
            _ => panic!("Invalid action: {}", action),
        };
        current = (current + offset).clamp(0, names.len() as i32 - 1);
    }
    println!("{}", names[current as usize]);
}

pub fn part2() {
    let lines = util::read_lines(1, 2);
    let names = lines[0].split(',').collect::<Vec<&str>>();
    let commands = lines[2].split(',').collect::<Vec<&str>>();
    let mut current = 0;
    for command in commands {
        let action = &command[0..1];
        let value: i32 = command[1..].parse().expect("Invalid number");
        current = match action {
            "R" => util::wrap_index(current + value, names.len() as i32),
            "L" => util::wrap_index(current - value, names.len() as i32),
            _ => panic!("Invalid action: {}", action),
        };
    }
    println!("{}", names[current as usize]);
}

pub fn part3() {
    let lines = util::read_lines(1, 3);
    let mut names = lines[0].split(',').collect::<Vec<&str>>();
    let commands = lines[2].split(',').collect::<Vec<&str>>();
    for command in commands {
        let action = command.chars().next().unwrap();
        let value: i32 = command[1..].parse().expect("Invalid number");
        let current = match action {
            'R' => util::wrap_index(value, names.len() as i32),
            'L' => util::wrap_index(-value, names.len() as i32),
            _ => panic!("Invalid action: {}", action),
        };
        names.swap(0, current as usize);
    }
    println!("{}", names[0]);
}

pub fn solve(part: u32) {
    match part {
        1 => part1(),
        2 => part2(),
        3 => part3(),
        _ => panic!("Part {} not implemented", part),
    }
}
