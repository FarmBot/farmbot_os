defmodule Mix.Tasks.Compile.Configurator do
  use Mix.Task
  @moduledoc """
    Compiles Configurator JS and HTML
  """

  def run(_args) do
    # IO.puts "Running `npm install`"
    # System.cmd("npm", ["install"])
    IO.puts "Building the javascripts"
    System.cmd("npm", ["run", "build"])
  end
end
