defmodule ParseGff3 do
  def main(_args) do
    ParseGff3.parse()
  end

  def stream_file(filepath) do
    # Cases. In Elixir, we can use function guards to define a function several times, matching a condition in the guard. In this case, I chose to use cases. They look similar to Rust's match expression. For functions with just a few lines, I like this better, as it is less verbose.
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
    # List comprehensions. Elixir can do list comprehensions. In this case, `into: %{}` tells Elixir to create a map, and the little pipeline below, send a tuple of `{key, value}` to the resulting map.
    for attr <- String.split(attrs_line, ";"), into: %{} do
      String.split(attr, "=") |> List.to_tuple()
    end
  end

  # Having the same function name with different argumentns is called function overloading. The way it works is similar to a `switch` statement in other languages. In this case, the arguments are matched to the structure of arguments in the function definitions in the order they are defined. If the match succeeds, that function will execute, and if it does not, the next function will be matched. I like this, because it makes function definitions more consice, as we can have a definition for each case.

  # Function pattern mathing. In Elixir, the `=` sign is not necessarily "equal", but a pattern matching operator. There is a whole discussion about it in several books, and it is outside of the scope of this article. For now, what is relevant is that it vcan be used to declare variables, but also to destructure and structurally match arguments from functions. For example, extract annotation will receive an argument, if that argument is a list with 9 elements, it will destructure the argument and assign the elements to `chrom`, `_source`, etc, and return a map with those values. If the argument cannot be destructured in 9 elements, the next `extract_annotation` will be matched. In this case, the `extract_annotation` just passes the data along.
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
    # Pipelines. If you are familiar with bash pipes, this will feel natural. In a nutshell, a pipeline sends the result of the previous function as the first argument of the next function. This is very convenient, as in a lot of data processing tasks, we take the output of one procedure to further process it with different programs.
    Path.expand("../../../data/gff3_parsing/Homo_sapiens.GRCh38.114.gff3.gz", __DIR__)

    # Streams. Streams in Elixir are lazy, so they don't load the whole file into memory. Instead, they read the file line by line, and send each line to the next function. This is very convenient for large files, as we don't need to load the whole file into memory. Most functions from the `Enum` module have implementations in `Stream`.
    |> stream_file()
    |> Stream.filter(fn x -> !String.starts_with?(x, "#") end)
    |> Stream.filter(fn x -> String.contains?(x, "ensembl_havana") end)
    |> Stream.map(fn x -> String.trim(x, "\n") |> String.split("\t") end)
    |> Stream.map(&extract_annotation/1)
    # Finishing with `Enum`. Returns values from `Stream` are lazy loaded. This means that they do not produce any persistent values, unless we trigger the computation. In this case, Sending the stream to `Enum.to_list` will force the computation, and return a list with all the values.
    |> Enum.to_list()
  end
end
