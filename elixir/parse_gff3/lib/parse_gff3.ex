defmodule ParseGff3 do
  def main(_args) do
    ParseGff3.parse()
  end

  def stream_file(filepath) do
    case Path.extname(filepath) do
      ".gz" ->
        File.stream!(filepath, [:compressed])

      ".gff3" ->
        File.stream!(filepath)

      ext ->
        IO.puts("The file #{filepath} requires an .gz or .gff3 extension, not #{ext}")
        exit(1)
    end
  end

  def parse_attrs(attrs_line) do
    for attr <- String.split(attrs_line, ";"), into: %{} do
      String.split(attr, "=") |> List.to_tuple()
    end
  end

  def extract_annotation([
        chrom,
        _source,
        feature_type,
        n_start,
        n_end,
        _score,
        strand,
        _phase,
        attrs
      ]) do
    %{
      region: chrom,
      feature_type: feature_type,
      start: String.to_integer(n_start),
      end: String.to_integer(n_end),
      strand: strand,
      attrs: parse_attrs(attrs)
    }
  end

  def extract_annotation(data), do: data

  def parse do
    Path.expand("../../../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz", __DIR__)
    |> stream_file()
    |> Stream.filter(fn x -> !String.starts_with?(x, "#") end)
    |> Stream.filter(fn x -> String.contains?(x, "ensembl_havana") end)
    |> Stream.map(fn x -> String.trim(x, "\n") |> String.split("\t") end)
    |> Stream.map(&extract_annotation/1)
    |> Enum.to_list()
  end
end
