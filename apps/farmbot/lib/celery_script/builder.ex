defmodule Farmbot.CeleryScript.Command.Builder do
  @moduledoc """
    Macros for creating CeleryScript Commands
  """
  @doc false
  defmacro __using__(_) do
    quote do
      import Farmbot.CeleryScript.Command.Builder
    end
  end

  @doc """
    Loads all .celery files.
  """
  defmacro import_all_commands do
    things = File.ls!(d)
    {command_files, _} = Enum.partition(things, fn(thing) ->
      String.contains?(thing, ".celery")
    end)

    for command <- command_files do
      [name, _] = String.split(command, ".")
      quote do import_command(unquote(name)) end
    end
  end

  @doc """
    Import a command from a file
  """
  defmacro import_command(file_name) do
    f =
      d <> "/#{file_name}.celery"
      |> File.read!
      |> Code.string_to_quoted!(file: "#{file_name}.celery")
    quote do
      unquote(f)
    end
  end

  defp d, do: "./lib/celery_script/commands"
end
