defmodule Farmbot.CeleryScript.Command.If do
  @moduledoc """
    If
  """

  alias  Farmbot.CeleryScript.{Command, Ast, Error}
  import Command, only: [do_command: 2]
  alias  Farmbot.Context
  use    Farmbot.DebugLog

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
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{_else: else_, _then: then_, lhs: lhs, op: op, rhs: rhs }, _, ctx) do
    left = lhs |> eval_lhs(ctx)
    unless is_integer(left) or is_nil(left) do
      raise Error, context: ctx,
        message: "could not evaluate left hand side of if statment! #{inspect lhs}"
    end

    eval_if({left, op, rhs}, then_, else_, ctx)
  end

  @spec eval_lhs(binary, Context.t) :: integer | nil | no_return
  defp eval_lhs(lhs, %Farmbot.Context{} = context) do
    [x, y, z] = Farmbot.BotState.get_current_pos(context)
    case lhs do
      "x"              -> x
      "y"              -> y
      "z"              -> z
      "pin" <> number  -> lookup_pin(context, number)
      unexpected_thing ->
        raise Error, context: context,
          message: "Got unexpected left hand side of IF: #{unexpected_thing}"
    end
  end

  @spec lookup_pin(Context.t, binary) :: integer | nil
  defp lookup_pin(context, number) do
    thing   = number |> String.trim |> String.to_integer
    pin_map = Farmbot.BotState.get_pin(context, thing)
    case pin_map do
      %{value: val} -> val
      nil           -> nil
    end
  end

  @spec eval_if({integer, String.t, integer},
    Ast.t, Ast.t, Context.t) :: Context.t

  # if the left hand side evaluated to nil, and the user wanted to check for
  # that particular thing, we evaluate the `then` branch
  defp eval_if({nil, "is_undefined", _}, then_, _, context) do
    print_and_execute(then_, "is_undefined", context)
  end

  # if the user was checking for undefined, but it was NOT nil ^ above
  # then we eval the `else` branch.
  defp eval_if({_, "is_undefined", _}, _then, else_, context) do
    print_and_execute(else_, "is not undefined", context)
  end

  # if the user was not checking for undefifned, but we got undefined,
  # raise an error. (this is basically javascript now.)
  defp eval_if({nil, _, _}, _then, _else, context) do
    raise Error, context: context,
      message: "Left hand side of IF evaluated to undefined!"
  end

  # standard if here down.
  defp eval_if({lhs, ">", rhs}, then_, else_, context) do
    if lhs > rhs,
      do: print_and_execute(then_, lhs > rhs, context),
    else: print_and_execute(else_, lhs > rhs, context)
  end

  defp eval_if({lhs, "<", rhs}, then_, else_, context) do
    if lhs < rhs,
      do: print_and_execute(then_, lhs < rhs, context),
    else: print_and_execute(else_, lhs < rhs, context)
  end

  defp eval_if({lhs, "is", rhs}, then_, else_, context) do
    if lhs == rhs,
      do: print_and_execute(then_, lhs == rhs, context),
    else: print_and_execute(else_, lhs == rhs, context)
  end

  defp eval_if({lhs, "not", rhs}, then_, else_, context) do
    if lhs != rhs,
      do: print_and_execute(then_, lhs != rhs, context),
    else: print_and_execute(else_, lhs != rhs, context)
  end

  defp eval_if({_, op, _}, _, _, context),
    do: raise Error, context: context,
      message: "Bad operator in if #{inspect op}"

  defp print_and_execute(%Ast{} = ast, bool, %Context{} = ctx) do
    debug_log "if evaluated: #{bool}, doing: #{inspect ast}"
    do_command(ast, ctx)
  end
end
