defmodule ExCoveralls.Stats do
  @moduledoc """
  Provide calculation logics of coverage stats.
  """
  alias ExCoveralls.Cover
  alias ExCoveralls.Settings

  defmodule Source do
    @moduledoc """
    Stores count information for a file and all source lines.
    """

    defstruct filename: "", coverage: 0, sloc: 0, hits: 0, misses: 0, source: []
  end

  defmodule Line do
    @moduledoc """
    Stores count information and source for a sigle line.
    """

    defstruct coverage: nil, source: ""
  end

  @doc """
  Report the statistical information for the specified module.
  """
  def report(modules) do
    calculate_stats(modules)
    |> generate_coverage
    |> generate_source_info
    |> skip_files
    |> ExCoveralls.StopWords.filter
    |> ExCoveralls.Ignore.filter
  end

  @doc """
  Calculate the statistical information for the specified list of modules.
  It uses :cover.analyse for getting the information.
  """
  def calculate_stats(modules) do
    Enum.reduce(modules, Map.new, fn(module, dict) ->
      {:ok, lines} = Cover.analyze(module)
      analyze_lines(lines, dict)
    end)
  end

  defp analyze_lines(lines, module_hash) do
    Enum.reduce(lines, module_hash, fn({{module, line}, count}, module_hash) ->
      add_counts(module_hash, module, line, count)
    end)
  end

  defp add_counts(module_hash, module, line, count) do
    path = Cover.module_path(module)
    count_hash = Map.get(module_hash, path, Map.new)
    Map.put(module_hash, path, Map.put(count_hash, line, max(Map.get(count_hash, line, 0), count)))
  end

  @doc """
  Generate coverage, based on the pre-calculated statistic information.
  """
  def generate_coverage(hash) do
    keys = Map.keys(hash)
    Enum.map(keys, fn(file_path) ->
      total = get_source_line_count(file_path)
      {file_path, do_generate_coverage(Map.fetch!(hash, file_path), total, [])}
    end)
  end

  defp do_generate_coverage(_hash, 0, acc),   do: acc
  defp do_generate_coverage(hash, index, acc) do
    count = Map.get(hash, index, nil)

    do_generate_coverage(hash, index - 1, [count | acc])
  end

  @doc """
  Generate objects which stores source-file and coverage stats information.
  """
  def generate_source_info(coverage) do
    Enum.map(coverage, fn({file_path, stats}) ->
      %{
        name: file_path,
        source: read_source(file_path),
        coverage: stats
      }
    end)
  end

  @doc """
  Append the name of the sub app to the source info stats.
  """
  def append_sub_app_name(stats, sub_app_name, apps_path) do
    Enum.map(stats, fn %{name: name} = stat ->
      %{stat | name: "#{apps_path}/#{sub_app_name}/#{name}"}
    end)
  end

  @doc """
  Returns total line counts of the specified source file.
  """
  def get_source_line_count(file_path) do
    read_source(file_path) |> count_lines
  end

  defp count_lines(string) do
    1 + (Regex.scan(~r/\n/i, string) |> length)
  end

  @doc """
  Returns the source file of the specified module.
  """
  def read_module_source(module) do
    Cover.module_path(module) |> read_source
  end

  @doc """
  Wrapper for reading the specified file.
  """
  def read_source(file_path) do
    ExCoveralls.PathReader.expand_path(file_path) |> File.read! |> trim_empty_prefix_and_suffix
  end

  def trim_empty_prefix_and_suffix(string) do
    string = Regex.replace(~r/\n\z/m, string, "")
    Regex.replace(~r/\A\n/m, string, "")
  end

  def skip_files(converage) do
    skip = Settings.get_skip_files
    Enum.reject(converage, fn cov ->
      Enum.any?(skip, &Regex.match?(&1, cov[:name]))
    end)
  end

  @doc """
  Summarizes source coverage details.
  """
  def source(stats, _patterns = nil), do: source(stats)
  def source(stats, _patterns = []),  do: source(stats)
  def source(stats, patterns) do
    Enum.filter(stats, fn(stat) -> String.contains?(stat[:name], patterns) end) |> source
  end

  def source(stats) do
    stats = Enum.sort(stats, fn(x, y) -> x[:name] <= y[:name] end)
    stats |> transform_cov
  end

  defp transform_cov(stats) do
    files = Enum.map(stats, &populate_file/1)
    {relevant, hits, misses} = Enum.reduce(files, {0,0,0}, &reduce_file_counts/2)
    covered = relevant - misses

    %{coverage: get_coverage(relevant, covered),
      sloc: relevant,
      hits: hits,
      misses: misses,
      files: files}
  end

  defp populate_file(stat) do
    coverage = stat[:coverage]
    source = map_source(stat[:source], coverage)
    relevant = Enum.count(coverage, fn e -> e != nil end)
    hits = Enum.reduce(coverage, 0, fn e, acc -> (e || 0) + acc end)
    misses = Enum.count(coverage, fn e -> e == 0 end)
    covered = relevant - misses

    %Source{filename: stat[:name],
      coverage: get_coverage(relevant, covered),
      sloc: relevant,
      hits: hits,
      misses: misses,
      source: source}
  end

  defp reduce_file_counts(%{sloc: sloc, hits: hits, misses: misses}, {s,h,m}) do
    {s+sloc, h+hits, m+misses}
  end

  defp get_coverage(relevant, covered) do
    value = case relevant do
      0 -> Settings.default_coverage_value
      _ -> (covered / relevant) * 100
    end

    if value == trunc(value) do
      trunc(value)
    else
      Float.round(value, 1)
    end
  end

  defp map_source(source, coverage) do
    source
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.map(&(populate_source(&1,coverage)))
  end

  defp populate_source({line, i}, coverage) do
    %Line{coverage: Enum.at(coverage, i) , source: line}
  end

  @doc """
  Exit the process with a status of 1 if coverage is below the minimum.
  """
  def ensure_minimum_coverage(stats) do
    coverage_options = ExCoveralls.Settings.get_coverage_options
    minimum_coverage = coverage_options["minimum_coverage"] || 0
    if minimum_coverage > 0, do: check_coverage_threshold(stats, minimum_coverage)
  end

  defp check_coverage_threshold(stats, minimum_coverage) do
    result = source(stats)
    if result.coverage < minimum_coverage do
      message = "FAILED: Expected minimum coverage of #{minimum_coverage}%, got #{result.coverage}%."
      IO.puts IO.ANSI.format([:red, :bright, message])
      exit({:shutdown, 1})
    end
  end

end
