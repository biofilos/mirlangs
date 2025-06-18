from pathlib import Path
from gzip import open as gopen

def parse_attrs(attrs_line) -> dict:
    """
    Converts a GFF3 attributes field into a dictionary
    :param attrs_line: GFF3-formatted annotation attributes
    :return: dictionary of attributes
    """
    items = [x.split("=") for x in attrs_line.split(";")]
    ann_raw = {x[0]: x[1] for x in items}
    return ann_raw

def parse_gff3(in_file: Path, source):
    open_fx = gopen if in_file.suffix == ".gz" else open
    parsed_features = []
    with open_fx(in_file, "rt") as file_h:
        for line in file_h:
            if not line.startswith("#"):
                if source in line:
                    chrom, _source, feature_type, start, end, _score, strand, _phase, attrs = line.strip().split("\t")
                    attrs_parsed = parse_attrs(attrs)
                    annotation = {
                        "region": chrom,
                        "feature_type": feature_type,
                        "start": int(start),
                        "end": int(end),
                        "strand": strand,
                        "attrs": attrs_parsed
                    }
                    parsed_features.append(annotation)
    return parsed_features

if __name__ == "__main__":
    # ensembl_havana are highly curated features. These are the ones we will capture
    annotation_source = "ensembl_havana"
    gff_file = Path("../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz")
    gff_dict = parse_gff3(gff_file, annotation_source)