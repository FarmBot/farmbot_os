defmodule Farmbot.CeleryScript.Command do
  @moduledoc ~s"""
    Actionable CeleryScript Commands.
    There should be very little side affects here. just serial commands and
    ways to execute those serial commands.
    this means minimal logging, minimal bot state changeing (if its not the
    result of a gcode) etc.
  """
  require Logger
  alias Farmbot.CeleryScript.Ast
  use Amnesia
  alias Farmbot.Sync.Database.ToolSlot
  use ToolSlot
  use Counter, __MODULE__

  @max_count 1_000

  celery =
    "lib/celery_script/commands/"
    |> File.ls!
    |> Enum.reduce([], fn(file_name, acc) ->
      case String.split(file_name, ".ex") do
        [file_name, ""] ->
          mod = Module.concat Farmbot.CeleryScript.Command,
            Macro.camelize(file_name)
          [{String.to_atom(file_name), mod} | acc]
        _ -> acc
      end
    end)

  for {fun, module} <- celery do
    defdelegate unquote(fun)(args, body), to: module, as: :run
  end

  # DISCLAIMER:
  # IF YOU SEE A HACK HERE RELATED TO A FIRMWARE COMMAND
  # IE: read_pin, write_pin, etc, DO NOT TRY TO FIX IT.
  # IT WORKS, AND DOES NOT CAUSE SIDE EFFECTS (unless it does ¯\_(ツ)_/¯)
  # (unless of course the arduino firmware is fixed.)

  # DISCLAIMER #2:
  # PLEASE MAKE SURE EVERYTHING IS TYPESPECED AND DOC COMMENENTED IN HERE.
  # SOME NODES, ARE HARD TO TEST,
  # AND SOME NODES CAN CAUSE CATASTROPHIC DISASTERS
  # ALSO THE COMPILER CAN'T PROPERLY CHECK SOMETHING BEING THAT THE ARGS ARE
  # NOT POSITIONAL.

  @doc ~s"""
    Convert an ast node to a coodinate or return :error.
  """
  @spec ast_to_coord(Ast.t) :: Farmbot.CeleryScript.Command.Coordinate.t | :error
  def ast_to_coord(ast)
  def ast_to_coord(%Ast{kind: "coordinate",
                        args: %{x: _x, y: _y, z: _z},
                        body: []} = already_done), do: already_done

  # NOTE(connor): don't change `tool_id_` back to `tool_id` what was happening
  # Amnesia builds local variables by the name of "tool_id", so it was looking
  # fortool_id == tool_id, which returned
  # all of them, because every toolslots tool_id
  # always equals that toolslots tool id lol
  @lint {Credo.Check.Refactor.PipeChainStart, false}
  def ast_to_coord(%Ast{kind: "tool", args: %{tool_id: tool_id_}, body: []}) do
    blah = Amnesia.transaction do
      ToolSlot.where(tool_id == tool_id_) |> Amnesia.Selection.values
    end
    case blah do
      [ts] -> coordinate(%{x: ts.x, y: ts.y, z: ts.z}, [])
      _ -> Logger.error ">> could not find tool_slot with tool_id: #{tool_id_}"
        :error
    end
  end

  # is this one a good idea?
  # there might be too expectations here: it could return the current position,
  # or 0
  def ast_to_coord(%Ast{kind: "nothing", args: _, body: _}) do
    coordinate(%{x: 0, y: 0, z: 0}, [])
  end

  def ast_to_coord(ast) do
    Logger.warn ">> no conversion from #{inspect ast} to coordinate"
    :error
  end

  @doc """
    Converts celery script pairs to tuples
  """
  @spec pairs_to_tuples([Farmbot.CeleryScript.Command.Pair.t]) :: [tuple]
  def pairs_to_tuples(config_pairs) do
    Enum.map(config_pairs, fn(%Ast{} = thing) ->
      if thing.args.label == nil do
        Logger.error("FINDME: #{inspect config_pairs}")
      end
      {thing.args.label, thing.args.value}
    end)
  end

  @doc ~s"""
    Executes an ast tree.
  """
  @spec do_command(Ast.t) :: :no_instruction | any
  def do_command(%Ast{} = ast) do
    check_count()
    kind = ast.kind
    fun_name = String.to_atom kind
    module = Module.concat Farmbot.CeleryScript.Command, Macro.camelize(kind)
    # print the comment if it exists
    if ast.comment, do: Logger.info ">> [#{fun_name}] - #{ast.comment}"

    cond do
       function_exported?(__MODULE__, fun_name, 2) ->
         dec_count()
         Kernel.apply(__MODULE__, fun_name, [ast.args, ast.body])
       Code.ensure_loaded?(module) ->
         dec_count()
         Kernel.apply(module, :run, [ast.args, ast.body])
       true ->
         Logger.error ">> has no instruction for #{inspect ast}"
         :no_instruction
    end
  end

  defp check_count do
    if get_count() < @max_count  do
      inc_count()
    else
      Logger.error ">> COUNT TOO HIGH!"
      reset_count()
      raise("TO MUCH RECURSION")
    end
  end

  # behaviour
  @callback run(map, [Ast.t]) :: any
end
