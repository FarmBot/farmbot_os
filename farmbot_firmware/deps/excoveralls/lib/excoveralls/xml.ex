defmodule ExCoveralls.Xml do
  @moduledoc """
  Generate XML output for results.
  """

  alias ExCoveralls.Settings

  @file_name "excoveralls.xml"

  @doc """
  Provides an entry point for the module.
  """
  def execute(stats, options \\ []) do
    stats
    |> generate_xml(Enum.into(options, %{})) 
    |> write_file(options[:output_dir])

    ExCoveralls.Local.print_summary(stats)
  end

  def generate_xml(stats, _options) do
    base_dir = Settings.get_xml_base_dir()
    "<coverage version=\"1\">" <> Enum.map_join(stats, fn %{name: name, coverage: coverage} ->
      path = String.replace("#{base_dir}/#{name}", ~r/(\/)+/, "/", global: true)
      "<file path=\"#{path}\">" <>
        Enum.map_join(Enum.with_index(coverage), fn 
          {nil, _line} -> ""
          {count, line} ->
            "<lineToCover lineNumber=\"#{line + 1}\" covered=\"#{count != 0}\"/>"
        end)
      <> "</file>"      
    end) <> "</coverage>"
  end

  defp output_dir(output_dir) do
    cond do
      output_dir ->
        output_dir
      true ->
        options = Settings.get_coverage_options
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
