defmodule Farmbot.CeleryScript.AST.Node.If do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:lhs, :op, :rhs, :_then, :_else]

  def execute(%{_else: else_, _then: then_, lhs: lhs, op: op, rhs: rhs }, _body, env) do
    env = mutate_env(env)
    left = eval_lhs(lhs)

    if is_number(left) or is_nil(left) do
      eval_if(left, op, rhs)
      |> fn(result) ->
        Logger.debug "IF evaluated to #{result}."
        result
      end.() # for debug purposes.
      |> do_jump(else_, then_, env)
    else
      {:error, "Lefthand could not be evaluated to a number (#{inspect left})", env}
    end
  end

  defp eval_lhs(:x), do: -1
  defp eval_lhs(:y), do: -1
  defp eval_lhs(:z), do: -1
  defp eval_lhs({:pin, pin}), do: -1

  defp eval_if(nil, :is_undefined, _), do: true
  defp eval_if(_,   :is_undefined, _), do: false
  defp eval_if(nil, _, _), do: {:error, "left hand side undefined."}

  defp eval_if(lhs, :>, rhs) when lhs > rhs, do: true
  defp eval_if(lhs, :>, rhs), do: false

  defp eval_if(lhs, :<, rhs) when lhs < rhs, do: true
  defp eval_if(lhs, :<, rhs), do: false

  defp eval_if(lhs, :==, rhs) when lhs == rhs, do: true
  defp eval_if(lhs, :==, rhs), do: false

  defp eval_if(lhs, :!=, rhs) when lhs != rhs, do: true
  defp eval_if(lhs, :!=, rhs), do: false

  defp do_jump({:error, reason} = err, _, _, env), do: {:error, reason, env}

  defp do_jump(true,  _else, then_, env), do: Farmbot.CeleryScript.execute(then_, env)
  defp do_jump(false, else_, _then, env), do: Farmbot.CeleryScript.execute(else_, env)

end
