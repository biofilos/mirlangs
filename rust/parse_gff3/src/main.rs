use flate2::read::GzDecoder;
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

type Attrs = HashMap<String, String>;

#[derive(Debug)]
struct Gene {
    chromosome: String,
    start: i32,
    end: i32,
    strand: String,
    attrs: Attrs,
}

fn parse_attrs(attrs_line: String) -> Attrs {
    let attrs: Attrs = attrs_line
        .split(";")
        .map(|x| {
            let mut split = x.split("=");
            let key = split.next().unwrap().to_string();
            let value = split.next().unwrap().to_string();
            (key, value)
        })
        .collect();
    attrs
}

impl Gene {
    fn new(gff_line: String) -> Self {
        let parts = gff_line.split("\t").collect::<Vec<&str>>();
        let chromosome = parts[0].to_string();
        let start = parts[3].parse::<i32>().unwrap();
        let end = parts[4].parse::<i32>().unwrap();
        let strand = parts[6].to_string();
        let attrs_line = parts[8].to_string();
        let attrs = parse_attrs(attrs_line);
        Self {
            chromosome,
            start,
            end,
            strand,
            attrs,
        }
    }
}

#[derive(Debug)]
struct Region {
    name: String,
    length: u64,
}
#[derive(Debug)]
struct Annotation {
    gff_version: u16,
    regions: Vec<Region>,
    genes: Vec<Gene>,
}

impl Annotation {
    fn new() -> Self {
        Self {
            gff_version: 0,
            regions: Vec::new(),
            genes: Vec::new(),
        }
    }
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
    fn add_gene(&mut self, gff_line: String) {
        self.genes.push(Gene::new(gff_line));
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
                    line if line.contains("\tensembl_havana\tgene\t") => {
                        annotation.add_gene(line);
                    }
                    _ => {
                        // Ignore other lines
                    }
                }
            }
            Err(e) => panic!("Error reading line: {e}"),
        }
    }
    println!("{:?}", annotation);
}
