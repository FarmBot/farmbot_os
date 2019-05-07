defmodule Mix.Tasks.Farmbot.Coveralls do
  @moduledoc """
  Mix Task to report the coverage for all of the individual projects that make
  up the repository.
  """
  
  use Mix.Task
  Module.register_attribute(__MODULE__, :projects, accumulate: true)
  @projects :farmbot_celery_script
  @projects :farmbot_core
  @projects :farmbot_ext
  @projects :farmbot_firmware
  @projects :farmbot_os

  def run(args) do
    @projects
    |> pmap(&read_coverage_json!/1)
    |> List.flatten()
    |> run_task(args)
  end

  def run_task(stats, []) do
    run_task(stats, ["local"])
  end

  def run_task(stats, ["local"]) do
    ExCoveralls.Local.execute(stats, [])
  end

  def run_task(stats, ["circle"]) do
    ExCoveralls.Circle.execute(stats, [])
  end

  def pmap(data, func) do
    data
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end

  def read_coverage_json!(project) do
    coverage_file = Path.join([to_string(project), "cover", "excoveralls.json"])
    with {:ok, bin} <- File.read(coverage_file),
         {:ok, json} <- Jason.decode(bin) do
          Enum.map(json["source_files"], fn(%{"name" => name, "source" => source, "coverage" => coverage}) ->
            %{name: Path.join([to_string(project), name]), source: source, coverage: coverage}
          end)
          else
          _ -> Mix.raise("""
          Could not read coverage JSON from #{coverage_file}. 
          Make sure to run `mix coveralls.json` in each project's parent
          directory.
          """)
         end
  end
end