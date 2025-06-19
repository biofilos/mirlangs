defmodule ParseGff3 do
  require IEx

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

  def collapse_regions(%{region: data}, acc) do
    new_region = %{data.region => %{start: data.start, end: data.end}}
    all_regions = Map.merge(acc.regions, new_region)
    acc = put_in(acc.regions, all_regions)
    acc
  end

  def collapse_regions(data, acc) do
    Map.merge(data, acc)
  end

  def parse_file do
    Path.expand("../../../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz", __DIR__)
    |> stream_file()
    |> Stream.filter(fn x -> String.starts_with?(x, "#") end)
    |> Stream.map(&ParseGff3.parse/1)
    |> Stream.filter(fn x -> x end)
    |> Enum.reduce(%{regions: %{}}, &collapse_regions/2)
  end
end

meh = ParseGff3.parse_file()
IO.inspect(meh)
