defmodule Mix.Tasks.Farmbot.CeleryScript.Compile do
  @moduledoc """
  Compile a json representation of CeleryScript
  """
  use Mix.Task

  def run([in_filename, out_filename]) do
    File.read!(in_filename)
    |> Jason.decode!()
    |> Farmbot.CeleryScript.AST.decode()
    |> Farmbot.CeleryScript.AST.Compiler.compile()
    # |> fn(data) -> 
    #   stuff = inspect(data, limit: :infinity)
    #   stuff = Code.format_string!(stuff)
    #   File.write!("ast.exs", stuff)
    #   data
    # end.()
    |> Macro.to_string()
    |> Code.format_string!()
    |> (fn data ->
          File.write!(out_filename, data)
        end).()
  end
end
