defmodule Farmbot.CeleryScript.Command.RpcRequest do
  @moduledoc """
    RpcOk
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Handles an RPC Request.
      args: %{label: String.t},
      body: [Ast.t,...]
  """
  @spec run(%{label: String.t}, [Ast.t, ...], Ast.context) :: Ast.context
  def run(%{label: id}, more_stuff, context) do
    more_stuff
    |> Enum.reduce({[],[]}, fn(ast, {win, fail}) ->
      fun_name = String.to_atom(ast.kind)
      if function_exported?(Command, fun_name, 3) do
        # actually do the stuff here?
        Command.do_command(ast, context)
        {[ast | win], fail}
      else
        new_context = Command.explanation(%{message: "unhandled: #{fun_name}"}, [], context)
        {exp, _} = Farmbot.Context.pop_data(new_context)
        Logger.error ">> got an unhandled rpc "
          <> "request: #{fun_name} #{inspect ast}"
        {win, [exp | fail]}
      end
    end)
    |> handle_req(id, context)
  end

  @spec handle_req(
    {Ast.t, [Command.Explanation.explanation_type]},
    binary,
    Ast.context) :: Ast.context
  defp handle_req({_, []}, id, context) do
    # there were no failed asts.
    context = Command.rpc_ok(%{label: id}, [], context)
    {item, context} = Farmbot.Context.pop_data(context)
    Farmbot.Transport.emit(item)
    context
  end

  defp handle_req({_, failed}, id, context) do
    # there were some failed asts.
    context = Command.rpc_error(%{label: id}, failed, context)
    {item, context} = Farmbot.Context.pop_data(context)
    Farmbot.Transport.emit(item)
    context
  end
end
