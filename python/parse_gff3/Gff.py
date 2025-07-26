from parse_gff import parse_gff3
from pathlib import Path
from dataclasses import dataclass
from gzip import open as gzopen


class BadGffVersion(Exception):
    def __init__(
        self,
        message="GFF is not version 3, or there is no version information in the header of the file",
    ):
        super().__init__(message)


@dataclass
class GffFeature:
    region: str
    feature_type: str
    start: int
    end: int
    strand: str
    attrs: dict


class Gff:
    def __init__(self, gff_file: Path) -> None:
        self.gff_file = gff_file
        self.meta = self.parse_meta()
        self.feats = [
            GffFeature(
                x["region"],
                x["feature_type"],
                x["start"],
                x["end"],
                x["strand"],
                x["attrs"],
            )
            for x in parse_gff3(gff_file, "ensembl_havana")
        ]
        self.n_features = len(self.feats)
        self.n_regions = len({x.region for x in self.feats})

    def parse_meta(self):
        open_fx = gzopen if self.gff_file.suffix == ".gz" else open
        meta_d = dict()
        with open_fx(self.gff_file, "rt") as f:
            for line in f:
                if line.startswith("#"):
                    key, *line_data = line.lstrip("##").lstrip("#!").split()
                    key = key.replace("-", "_")
                    if key not in meta_d:
                        meta_d[key] = (
                            " ".join(line_data)
                            if line.startswith("#!") or "gff_version" == key
                            else [line_data]
                        )
                    else:
                        meta_d[key].append(line_data)
                else:
                    break
        if "sequence_region" in meta_d:
            fixed_regions = [None] * len(meta_d["sequence_region"])
            for ix, region_data in enumerate(meta_d["sequence_region"]):
                region, start, end = region_data
                region_dict = dict(region=region, start=int(start), end=int(end))
                fixed_regions[ix] = region_dict

        meta_d["regions"] = fixed_regions
        del meta_d["sequence_region"]
        if meta_d.get("gff_version", None) != "3":
            raise BadGffVersion
        return meta_d

    def __str__(self):
        info = (
            f"GFF file: {self.gff_file}\n"
            "Summary\n"
            f"{self.n_features} features in {self.n_regions} regions"
        )
        return info


if __name__ == "__main__":
    gff_in = Path("../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz")
    gff = Gff(gff_in)
    print(gff)
