defmodule ExCoveralls.Settings do
  @moduledoc """
  Handles the configuration setting defined in json file.
  """

  defmodule Files do
    @filename "coveralls.json"
    def default_file, do: "#{Path.dirname(__ENV__.file)}/../conf/#{@filename}"
    def custom_file, do: Application.get_env(:excoveralls, :config_file, "#{File.cwd!}/#{@filename}")
    def dot_file, do: Path.expand("~/.excoveralls/#{@filename}")
  end

  @doc """
  Get stop words from the json file.
  The words are taken as regular expression.
  """
  def get_stop_words do
    read_config("default_stop_words", []) ++ read_config("custom_stop_words", [])
      |> Enum.map(&Regex.compile!/1)
  end

  @doc """
  Get coverage options from the json file.
  """
  def get_coverage_options do
    read_config("coverage_options", []) |> Enum.into(Map.new)
  end

  @doc """
  Get default coverage value for lines marked as not relevant.
  """
  def default_coverage_value do
    case Map.fetch(get_coverage_options(), "treat_no_relevant_lines_as_covered") do
      {:ok, true} -> 100.0
      _           -> 0.0
    end
  end

  @doc """
  Get terminal output options from the json file.
  """
  def get_terminal_options do
    read_config("terminal_options", []) |> Enum.into(Map.new)
  end

  @doc """
  Get column width to use for the report from the json file
  """
  def get_file_col_width do
    case Map.fetch(get_terminal_options(), "file_column_width") do
      {:ok, val} when is_binary(val) ->
        case Integer.parse(val) do
          :error -> 40
          {int, _} -> int
        end
      {:ok, val} when is_integer(val) -> val
      _ -> 40
    end
  end

  def get_print_files do
    case Map.fetch(get_terminal_options(), "print_files") do
      {:ok, val} when is_boolean(val) -> val
      _ -> true
    end
  end

  defp read_config_file(file_name) do
    if File.exists?(file_name) do
      case File.read!(file_name) |> Jason.decode do
        {:ok, config} -> config
        _ -> raise "Failed to parse config file as JSON : #{file_name}"
      end
    else
      Map.new
    end
  end

  @doc """
  Get xml base dir
  """
  def get_xml_base_dir do
    Map.get(get_coverage_options(), "xml_base_dir", "")
  end

  @doc """
  Get skip files from the json file.
  """
  def get_skip_files do
    read_config("skip_files", [])
    |> Enum.map(&Regex.compile!/1)
  end

  def get_print_summary do
    read_config("print_summary", true)
  end

  @doc """
  Reads the value for the specified key defined in the json file.
  """
  def read_config(key, default \\ nil) do
    case (read_merged_config(Files.dot_file, Files.custom_file) |> Map.get(key)) do
      nil    -> read_config_file(Files.default_file()) |> Map.get(key, default)
      config -> config
    end
  end

  defp read_merged_config(dot, custom) do
    read_config_file(dot)
    |> merge(read_config_file(custom))
  end

  defp merge(left, right) when is_map(left) and is_map(right) do
    keys = Map.keys(left) ++ Map.keys(right)
    Enum.reduce(keys, %{}, fn k, new_map ->
      merged = cond do
        Map.has_key?(left, k) and Map.has_key?(right, k) -> merge(Map.get(left, k), Map.get(right, k))
        Map.has_key?(left, k) == false and Map.has_key?(right, k) -> Map.get(right, k)
        Map.has_key?(left, k) and Map.has_key?(right, k) == false -> Map.get(left, k)
        true -> %{}
      end
      Map.put(new_map, k, merged)
    end)
  end
  defp merge(left, right) when is_list(left) and is_list(right), do: Enum.uniq(left ++ right)
  defp merge(_left, right), do: right
end
