# Structs. In Elixir, structs are similar to structs in Rust or Go. Basically, we declare a module with named fields. This is usually not absolutely required, but it can give the code more clarity, and it is very useful when matching functions that have to interact with specific structs. In this case, we have 2 named structs `GFFfeature`, and `RegionHeader`  that will be executed by different versions of `collapse_regions` depending on what kind of struct is passed to the function.
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

  # Matching functions to the beginning of a string. In order to rexecute a function when a string starts with a specific substring, we use the pattern `"##" <> rest` in the function signature. The `<>` operator concatenate strings, so in this case, the argument passed to the function will try to be reconstructed with the `<>` operator where the match will be successful only if the first part of the string is `"##"`. As a bonus, the variable `rest` can be used in the body of the function.
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

  # List processing. In Elixir, lists can be destructured by using the syntax `[head | tail]`. This will assign the first element of the list to `head`, and the rest of the list to `tail`. Similary, one can add elements efficiently to a list with the pattern `[new_element | old_list]`. The issue with this, is that the new element is added to the beginning of the list, so we have to reverse the list at the end. This pattern is so common, that Elixir has optimized this process, so there is not a big performance penalties for using this approach.
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
      # Map and anonymous functions. Anonymous functions can be defined in different ways. In this case , the syntax `&parse/1` means "convert the function `parse` that accepts one argument (`/1`) to an anonymous function", and now we can use `parse/1` in our pipeline.
      |> Stream.map(&parse/1)
      |> Enum.reduce(%{regions: %{}, features: [], metadata: %{}}, &collapse_regions/2)

    Map.update!(parsed_features, :features, &Enum.reverse/1)
  end
end
