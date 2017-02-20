defmodule Mix.Tasks.CS.New do
  use Mix.Task
  @shortdoc "Creates a new celery script command"
  def run([new_cs]) do
    IO.puts "Defining new Celery Script command: #{new_cs}"
    module_string =
      new_cs
      |> Macro.camelize
      |> build_module
    path = "lib/celery_script/commands/#{new_cs}.ex"
    File.write path, module_string
  end

  def run(_), do: Mix.raise("Unexpected args!")

  defp build_module(camelized_kind) do
    """
    defmodule Farmbot.CeleryScript.Command.#{camelized_kind} do
      #{build_module_doc(camelized_kind)}

      alias Farmbot.CeleryScript.Ast
      alias Farmbot.CeleryScript.Command
      require Logger
      @behaviour Command

      #{build_run_doc(camelized_kind) |> String.trim}
      @spec run(%{}, []) :: no_return
      def run(%{}, []) do
        #TODO Finish #{camelized_kind}
      end

    end
    """
  end

  defp build_run_doc(camelized_kind) do
    ~s(@doc ~s"""
    #{camelized_kind}
    args: %{},
    body: []\n  """)
  end

  defp build_module_doc(camelized_kind) do
    ~s(@moduledoc """
    #{camelized_kind}\n  """)
  end
end
