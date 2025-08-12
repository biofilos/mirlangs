use flate2::read::GzDecoder;
use std::fs::File;
use std::io::{BufRead, BufReader};

fn read_file() -> Result<BufReader<GzDecoder<File>>, std::io::Error> {
    let file = File::open("../../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz")?;
    let gz_decoder = GzDecoder::new(file);
    let reader = BufReader::new(gz_decoder);
    Ok(reader)
}

fn main() {
    let file_reader = match read_file() {
        Ok(file) => file,
        Err(e) => panic!("Error reading file: {e}"),
    };

    for line in file_reader.lines() {
        match line {
            Ok(line) => println!("{line}"),
            Err(e) => panic!("Error reading line: {e}"),
        }
    }
}
