defmodule RegionHeader do
  defstruct [:region, :start, :end]
end

defmodule GFFfeature do
  defstruct [:region, :feature_type, :start, :end, :strand, :attrs]

  def new(map) do
    struct(__MODULE__, map)
  end
end

defmodule ParseAllGff3 do
  def main(_args) do
    parse_file()
  end

  def parse("##" <> rest) do
    [ix | body] = String.trim(rest, "\n") |> String.split()

    case ix do
      "sequence-region" ->
        [region, n_start, n_end] = body

        %RegionHeader{
          region: region,
          start: String.to_integer(n_start),
          end: String.to_integer(n_end)
        }

      "gff-version" ->
        [ver | _] = body
        %{gff_version: ver}

      _ ->
        nil
    end
  end

  def parse("#!" <> rest) do
    [ix | body] = String.trim(rest, "\n") |> String.split()
    [first | rest] = body
    joined = Enum.reduce(rest, first, fn x, a -> a <> " " <> x end)

    %{(ix |> String.replace("-", "_") |> String.to_atom()) => joined}
  end

  def parse(line) do
    line
    |> String.trim("\n")
    |> String.split("\t")
    |> ParseGff3.extract_annotation()
    |> GFFfeature.new()
  end

  def collapse_regions(%GFFfeature{} = data, acc) do
    put_in(acc.features, [data | acc.features])
  end

  def collapse_regions(%RegionHeader{} = data, acc) do
    new_region = %{data.region => %{start: data.start, end: data.end}}
    all_regions = Map.merge(acc.regions, new_region)
    put_in(acc.regions, all_regions)
  end

  def collapse_regions(%{} = data, acc) do
    meta = Map.merge(data, acc.metadata)
    put_in(acc.metadata, meta)
  end

  def collapse_regions(nil, acc) do
    acc
  end

  def parse_file() do
    parsed_features =
      Path.expand("../../../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz", __DIR__)
      |> ParseGff3.stream_file()
      |> Stream.map(&parse/1)
      |> Enum.reduce(%{regions: %{}, features: [], metadata: %{}}, &collapse_regions/2)

    Map.update!(parsed_features, :features, &Enum.reverse/1)
  end
end
