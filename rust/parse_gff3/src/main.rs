use flate2::read::GzDecoder;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Debug)]
struct Region {
    name: String,
    length: u64,
}
#[derive(Debug)]
struct Annotation {
    gff_version: u16,
    regions: Vec<Region>,
}

impl Annotation {
    fn new() -> Self {
        Self {
            gff_version: 0,
            regions: Vec::new(),
        }
    }
}

impl Annotation {
    fn set_version(&mut self, gff_line: String) {
        let version_str = gff_line.split(" ").nth(1).unwrap().to_string();
        let version_num = match version_str.parse::<u16>() {
            Ok(version_num) => version_num,
            Err(e) => panic!("Error parsing version number: {e}"),
        };
        self.gff_version = version_num;
    }

    fn add_region(&mut self, gff_line: String) {
        let fields = gff_line.split_whitespace().collect::<Vec<&str>>();
        let length = match fields[3].parse::<u64>() {
            Ok(length) => length,
            Err(e) => panic!("Error parsing length: {e}"),
        };
        let name = fields[1].to_string();
        self.regions.push(Region { name, length });
    }
}

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
    let mut annotation = Annotation::new();
    for line in file_reader.lines() {
        match line {
            Ok(line) => {
                match line {
                    line if line.starts_with("##gff-version") => {
                        annotation.set_version(line);
                    }
                    line if line.starts_with("##sequence-region") => {
                        annotation.add_region(line);
                    }
                    _ => {
                        // Ignore other lines
                    }
                }
            }
            Err(e) => panic!("Error reading line: {e}"),
        }
    }
    println!("{annotation:?}");
}
