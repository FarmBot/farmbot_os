defmodule ExCoveralls.Json do
  @moduledoc """
  Generate JSON output for results.
  """

  @file_name "excoveralls.json"

  @doc """
  Provides an entry point for the module.
  """
  def execute(stats, options \\ []) do
    generate_json(stats, Enum.into(options, %{})) |> write_file(options[:output_dir])

    ExCoveralls.Local.print_summary(stats)
  end

  def generate_json(stats, _options) do
    Jason.encode!(%{
      source_files: stats
    })
  end

  defp output_dir(output_dir) do
    cond do
      output_dir ->
        output_dir
      true ->
        options = ExCoveralls.Settings.get_coverage_options
        case Map.fetch(options, "output_dir") do
          {:ok, val} -> val
          _ -> "cover/"
        end
    end
  end

  defp write_file(content, output_dir) do
    file_path = output_dir(output_dir)
    unless File.exists?(file_path) do
      File.mkdir_p!(file_path)
    end
    File.write!(Path.expand(@file_name, file_path), content)
  end

end
