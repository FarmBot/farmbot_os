defmodule Farmbot.CeleryScript.AST.Node.If do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger

  allow_args [:lhs, :op, :rhs, :_then, :_else]

  def execute(%{_else: else_, _then: then_, lhs: lhs, op: op, rhs: rhs }, _body, env) do
    env = mutate_env(env)
    left = eval_lhs(lhs)

    if is_number(left) or is_nil(left) do
      eval_if(left, op, rhs)
      # |> fn(result) ->
      #   Logger.debug 2, "IF evaluated to #{inspect result}."
      #   result
      # end.() # for debug purposes.
      |> do_jump(else_, then_, env)
    else
      {:error, "Lefthand could not be evaluated to a number (#{inspect left})", env}
    end
  end

  defp eval_lhs(axis) when axis in [:x, :y, :z] do
    Farmbot.BotState.get_current_pos |> Map.get(axis)
  end

  defp eval_lhs({:pin, pin}) do
    case Farmbot.BotState.get_pin_value(pin) do
      {:ok, val} -> val
      {:error, :unknown_pin} -> nil
      {:error, reason} -> {:error, reason}
    end
  end

  defp eval_if(nil, :is_undefined, _), do: true
  defp eval_if(_,   :is_undefined, _), do: false
  defp eval_if(nil, _, _), do: {:error, "Could not eval IF because left hand side of if statement is undefined."}

  defp eval_if(lhs, :>, rhs) when lhs > rhs, do: true
  defp eval_if(_lhs, :>, _rhs), do: false

  defp eval_if(lhs, :<, rhs) when lhs < rhs, do: true
  defp eval_if(_lhs, :<, _rhs), do: false

  defp eval_if(lhs, :==, rhs) when lhs == rhs, do: true
  defp eval_if(_lhs, :==, _rhs), do: false

  defp eval_if(lhs, :!=, rhs) when lhs != rhs, do: true
  defp eval_if(_lhs, :!=, _rhs), do: false

  defp do_jump({:error, reason}, _, _, env), do: {:error, reason, env}

  defp do_jump(true,  _else, then_, env), do: Farmbot.CeleryScript.execute(then_, env)
  defp do_jump(false, else_, _then, env), do: Farmbot.CeleryScript.execute(else_, env)

end
