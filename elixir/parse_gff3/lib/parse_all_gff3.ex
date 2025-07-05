defmodule ParseAllGff3 do
  require IEx

  def main(_args) do
    parse_file()
    |> Enum.take(3)
    |> IO.inspect()
  end

  def parse("##" <> rest) do
    [ix | body] = String.trim(rest, "\n") |> String.split()

    case ix do
      "sequence-region" ->
        [region, n_start, n_end] = body
        %{region: %{region: region, start: n_start, end: n_end}}

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
    line |> String.trim("\n") |> String.split("\t") |> ParseGff3.extract_annotation()
  end

  def collapse_regions(%{attrs: _} = data, acc) do
    acc = put_in(acc.features, [data | acc.features])
    acc
  end

  def collapse_regions(%{region: data}, acc) do
    new_region = %{data.region => %{start: data.start, end: data.end}}
    all_regions = Map.merge(acc.regions, new_region)
    acc = put_in(acc.regions, all_regions)
    acc
  end

  def collapse_regions(nil, acc) do
    acc
  end

  def collapse_regions(data, acc) do
    meta = Map.merge(data, acc.metadata)
    acc = put_in(acc.metadata, meta)
    acc
  end

  def parse_file() do
    parsed_features =
      Path.expand("../../../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz", __DIR__)
      |> ParseGff3.stream_file()
      # |> Stream.filter(fn x -> String.starts_with?(x, "#") end)
      |> Stream.map(&parse/1)
      |> Enum.reduce(%{regions: %{}, features: [], metadata: %{}}, &collapse_regions/2)

    Map.update!(parsed_features, :features, &Enum.reverse/1)
  end
end
