from pathlib import Path
from gzip import open as gopen


def parse_attrs(attrs_line) -> dict:
    """
    Converts a GFF3 attributes field into a dictionary
    :param attrs_line: GFF3-formatted annotation attributes
    :return: dictionary of attributes
    """
    # List and dictionary comprehensions are powerful tools to easily parse collections of data into dictionary and list data structures. **If** they are short and concise, they are quite easy to read. However, for complex processing logic, use a for-loop
    items = [x.split("=") for x in attrs_line.split(";")]
    ann_raw = {x[0]: x[1] for x in items}
    return ann_raw


def parse_gff3(in_file: Path, source):
    # Working with gzipped files is very similar to working with normal text files. Since both functions use a similar function signature, I can just use the appropriate function with the same arguments, and it will just work (Note, this might be different when working with binary files)
    open_fx = gopen if in_file.suffix == ".gz" else open
    parsed_features = []
    with open_fx(in_file, "rt") as file_h:
        for line in file_h:
            if not line.startswith("#"):
                if source in line:
                    # I can use list destructuring to assign the elements of a list (the result of the `split` method) to individual variables. [Line 33]
                    (
                        chrom,
                        _source,
                        feature_type,
                        start,
                        end,
                        _score,
                        strand,
                        _phase,
                        attrs,
                        # String manipulation is straight-forward. Most string methods can be chained. In that way, I can keep adding methods to my parsing functionality and see the result seach time. This pattern makes string-parsing easy in Python
                    ) = line.strip().split("\t")
                    attrs_parsed = parse_attrs(attrs)
                    annotation = {
                        "region": chrom,
                        "feature_type": feature_type,
                        # Casting variables to other data types is easy [Lines 38, 39]. In this case, we can assume that the columns four and five will always be integers, however, in non-trivial cases, casting variables to other data types can crash the script or silently assign data to the wrong type.
                        "start": int(start),
                        "end": int(end),
                        "strand": strand,
                        "attrs": attrs_parsed,
                    }
                    # Adding elements to a list is quite easy. However, keep in mind that Python will generate a new list and copy all elements in the list plus the new element every time a list is updated, which will have performance issues with long lists. Ideally, if we know the size of the list in advance, it is ideal to initialize a list with empty items and assign elements to the list rather than appending new element to it. If the size of the list is not known in advance, several techniques exist to ameliorate the performance issues that appending to a list bring.
                    parsed_features.append(annotation)
    return parsed_features


if __name__ == "__main__":
    # ensembl_havana are highly curated features. These are the ones we will capture
    annotation_source = "ensembl_havana"
    gff_file = Path("../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz")
    gff_dict = parse_gff3(gff_file, annotation_source)
