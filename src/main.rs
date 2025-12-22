mod quests;
mod util;

use clap::Parser;
use quests::quest01;

#[derive(Parser)]
#[command(version, about = "Everybody Codes 2025", long_about = None)]
struct Args {
    #[arg(help = "Quest number")]
    quest: u32,
    #[arg(help = "Part number")]
    part: u32,
}

fn main() {
    let args = Args::parse();
    match args.quest {
        1 => quest01::solve(args.part),
        _ => println!("Quest {} not implemented", args.quest),
    }
}
