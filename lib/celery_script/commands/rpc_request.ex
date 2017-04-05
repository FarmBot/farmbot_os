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
  @spec run(%{label: String.t}, [Ast.t, ...]) :: no_return
  def run(%{label: id}, more_stuff) do
    more_stuff
    |> Enum.reduce({[],[]}, fn(ast, {win, fail}) ->
      fun_name = String.to_atom(ast.kind)
      if function_exported?(Command, fun_name, 2) do
        # actually do the stuff here?
        spawn fn() ->
          Command.do_command(ast)
        end
        {[ast | win], fail}
      else
        exp = Command.explanation(%{message: "unhandled: #{fun_name}"}, [])
        Logger.error ">> got an unhandled rpc request: #{fun_name} #{inspect ast}"
        {win, [exp | fail]}
      end
    end)
    |> handle_req(id)
  end

  @spec handle_req({Ast.t, [Command.Explanation.explanation_type]}, String.t) :: no_return
  defp handle_req({_, []}, id) do
    # there were no failed asts.
    %{label: id} |> Command.rpc_ok([]) |> Farmbot.Transport.emit
  end

  defp handle_req({_, failed}, id) do
    # there were some failed asts.
    %{label: id} |> Command.rpc_error(failed) |> Farmbot.Transport.emit
  end
end
