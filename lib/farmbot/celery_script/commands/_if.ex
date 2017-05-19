defmodule Farmbot.CeleryScript.Command.If do
  @moduledoc """
    If
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
  require Logger

  @behaviour Command

  @doc ~s"""
    Conditionally does something
      args: %{_else: Ast.t
              _then: Ast.t,
              lhs: String.t,
              op: "<" | ">" | "is" | "not",
              rhs: integer},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{_else: else_, _then: then_, lhs: lhs, op: op, rhs: rhs }, [], ctx) do
    left = lhs |> eval_lhs(ctx)
    unless is_integer(left) do
      raise "could not evaluate left hand side of if statment! #{inspect lhs}"
    end

    eval_if({left, op, rhs}, then_, else_, ctx)
  end

  # figure out what the user wanted
  @spec eval_lhs(binary, Ast.context) :: integer

  defp eval_lhs("pin" <> num, %Farmbot.Context{} = context) do
    thing = String.to_integer(num)
    Farmbot.BotState.get_pin(context, thing) || {:error, "pin" <> num}
  end

  defp eval_lhs(axis, %Farmbot.Context{} = context) do
    [x, y, z] = Farmbot.BotState.get_current_pos(context)
    case axis do
      "x" -> x
      "y" -> y
      "z" -> z
    end
  end

  @spec eval_if({integer, String.t, integer},
    Ast.t, Ast.t, Ast.context) :: Ast.context

  defp eval_if({lhs, ">", rhs}, then_, else_, context) do
    if lhs > rhs,
      do:   Command.do_command(then_, context),
    else: Command.do_command(else_, context)
  end

  defp eval_if({lhs, "<", rhs}, then_, else_, context) do
    if lhs < rhs,
      do:   Command.do_command(then_, context),
    else: Command.do_command(else_, context)
  end

  defp eval_if({lhs, "is", rhs}, then_, else_, context) do
    if lhs == rhs,
      do: Command.do_command(then_, context),
    else: Command.do_command(else_, context)
  end

  defp eval_if({lhs, "not", rhs}, then_, else_, context) do
    if lhs != rhs,
      do: Command.do_command(then_, context),
    else: Command.do_command(else_, context)
  end

  defp eval_if({_, _, _}, _, _, _context), do: raise "Bad operator in if!"
end
