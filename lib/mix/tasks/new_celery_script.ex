defmodule Mix.Tasks.Cs.New do
  @moduledoc false
  use Mix.Task
  @shortdoc "Creates a new celery script command"
  def run([new_cs]) do
    IO.puts "Defining new Celery Script command: #{new_cs}"
    module_string =
      new_cs
      |> Macro.camelize
      |> build_module

    module_test_string =
      new_cs
      |> Macro.camelize
      |> build_test_module

    new_cs_path = "lib/farmbot/celery_script/commands/#{new_cs}.ex"
    new_cs_test_path = "test/farmbot/celery_script/commands/#{new_cs}_test.exs"
    if File.exists?(new_cs_path) do
      Mix.raise("#{new_cs} already exists!!!!")
    end
    :ok = File.write new_cs_path, module_string
    :ok = File.write new_cs_test_path, module_test_string
  end

  def run(_), do: Mix.raise("Unexpected args!")

  defp build_test_module(camelized_kind) do
    """
    defmodule Farmbot.CeleryScript.Command.#{camelized_kind}Test do
      use ExUnit.Case
      alias Farmbot.CeleryScript.Ast
      alias Farmbot.CeleryScript.Command

      test "the truth" do
        # TODO(Connor) fix the truth in #{camelized_kind}
        assert true == false
      end
    end
    """
  end

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
