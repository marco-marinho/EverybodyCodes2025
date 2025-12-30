use std::fs;

#[rustler::nif]
pub fn rato() {
    let input = fs::read_to_string("data/quest09_2.txt").unwrap_or("".to_string());
    let lines = input.lines().map(|x| x.split(":").nth(1).unwrap_or(""));
    for line in lines {
        println!("{}", line);
    }
    println!("Rato!");
}

rustler::init!("librs");
