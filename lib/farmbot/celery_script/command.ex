defmodule Farmbot.CeleryScript.Command do
  @moduledoc ~s"""
    Actionable CeleryScript Commands.
    There should be very little side affects here. just serial commands and
    ways to execute those serial commands.
    this means minimal logging, minimal bot state changeing (if its not the
    result of a gcode) etc.
  """
  alias   Farmbot.CeleryScript.Ast
  alias   Farmbot.Database.Selectors
  require Logger
  use     Farmbot.DebugLog

  celery =
    "lib/farmbot/celery_script/commands/"
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
    defdelegate unquote(fun)(args, body, context), to: module, as: :run
  end

  # DISCLAIMER:
  # PLEASE MAKE SURE EVERYTHING IS TYPESPECED AND DOC COMMENENTED IN HERE.
  # SOME NODES, ARE HARD TO TEST,
  # AND SOME NODES CAN CAUSE CATASTROPHIC DISASTERS
  # ALSO THE COMPILER CAN'T PROPERLY CHECK SOMETHING BEING THAT THE ARGS ARE
  # NOT POSITIONAL.

  @doc ~s"""
    Convert an ast node to a coodinate or return :error.
  """
  @spec ast_to_coord(Ast.context, Ast.t) :: Ast.context
  def ast_to_coord(context, ast)
  def ast_to_coord(
    %Farmbot.Context{} = context,
    %Ast{kind: "coordinate",
         args: %{x: _x, y: _y, z: _z},
         body: []} = already_done),
   do: Farmbot.Context.push_data(context, already_done)

  def ast_to_coord(
    %Farmbot.Context{} = context,
    %Ast{kind: "tool", args: %{tool_id: tool_id}, body: []})
  do
    ts = nil
    if ts do
      next_context = coordinate(%{x: ts.x, y: ts.y, z: ts.z}, [], context)
      raise_if_not_context_or_return_context("coordinate", next_context)
    else
      raise "Could not find tool_slot with tool_id: #{tool_id}"
    end
  end

  # is this one a good idea?
  # there might be two expectations here: it could return the current position,
  # or 0
  def ast_to_coord(%Farmbot.Context{} = context, %Ast{kind: "nothing", args: _, body: _}) do
    next_context = coordinate(%{x: 0, y: 0, z: 0}, [], context)
    raise_if_not_context_or_return_context("coordinate", next_context)
  end

  def ast_to_coord(%Farmbot.Context{} = context,
                   %Ast{kind: "point",
                        args: %{pointer_type: pt_t, pointer_id: pt_id},
                        body: _}) do
    %{body: p}   = Selectors.find_point(context.database, pt_t, pt_id)
    next_context = coordinate(%{x: p.x, y: p.y, z: p.z}, [], context)
    raise_if_not_context_or_return_context("coordinate", next_context)
  end

  def ast_to_coord(%Farmbot.Context{} = context, %Ast{} = ast) do
    raise "No implicit conversion from #{inspect ast} to coordinate! context: #{inspect context}"
  end

  @doc """
    Converts celery script pairs to tuples
  """
  @spec pairs_to_tuples([Farmbot.CeleryScript.Command.Pair.t]) :: [tuple]
  def pairs_to_tuples(config_pairs) do
    Enum.map(config_pairs, fn(%Ast{} = thing) ->
      if thing.args.label == nil do
        Logger.error("Label was nil! #{inspect config_pairs}")
      end
      {thing.args.label, thing.args.value}
    end)
  end

  defp maybe_print_comment(nil, _), do: :ok
  defp maybe_print_comment(comment, fun_name),
    do: Logger.info ">> [#{fun_name}] - #{comment}"

  @doc ~s"""
    Executes an ast tree.
  """
  @spec do_command(Ast.t, Ast.context) :: Ast.context | no_return
  def do_command(%Ast{} = ast, context) do
    kind = ast.kind
    module = Module.concat Farmbot.CeleryScript.Command, Macro.camelize(kind)

    # print the comment if it exists
    maybe_print_comment(ast.comment, kind)

    if Code.ensure_loaded?(module) do
      try do
        next_context = Kernel.apply(module, :run, [ast.args, ast.body, context])
        raise_if_not_context_or_return_context(kind, next_context)
      rescue
        e ->
          debug_log("Could not execute: #{inspect ast}, #{inspect e}")
          Logger.error ">> could not execute #{inspect ast} #{inspect e}"
          stack_trace = System.stacktrace
          reraise(e, stack_trace)
      end
    else
      raise ">> has no instruction for #{inspect ast}"
    end
  end

  def do_command(not_cs_node, _) do
    raise ">> can not handle: #{inspect not_cs_node}"
  end

  defp raise_if_not_context_or_return_context(_, %Farmbot.Context{} = next), do: next
  defp raise_if_not_context_or_return_context(last_kind, not_context) do
    raise "[#{last_kind}] bad return value! #{inspect not_context}"
  end

  # behaviour
  @callback run(Ast.args, [Ast.t], Ast.context) :: Ast.context
end
