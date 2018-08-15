defmodule Farmbot.OS.IOLayer.Farmware do
  require Farmbot.Logger

  def first_party(_args, []) do
    {:error, "not implemented"}
  end

  def install(%{url: _url}, []) do
    {:error, "not implemented"}
  end

  def update(%{package: _name}, []) do
    {:error, "not implemented"}
  end

  def remove(%{package: _name}, []) do
    {:error, "not implemented"}
  end

  def execute(%{package: _name}, []) do
    {:error, "not implemented"}
  end

  # 1)  Check if Farmware is already running
  # 1a) Farmware isn't running - start it.
  # 1b) Farmware is running - continute.
  # 2)  check if there is a rpc_request to process.
  # 2a) there is a request - queue it
  # 2b) there is not a request - continue.
  # 3)  check if server is still alive
  # 3a) The server is still alive - continue
  # 3b) the server is not still alive - exit
  # def do_execute(fw) do
  #   case Server.lookup(fw) do
  #     {:ok, pid} -> pid
  #     {:error, {:already_started, pid}} -> pid
  #   end
  #   |> Server.is_alive?()
  #   |> case do
  #     true ->
  #       case Server.get_request(pid) do
  #         {:ok, request} -> {:ok, request}
  #         nil -> {:ok, %Farmbot.CelerScript.AST.new(:rpc_request, %{args: "noop"}, [])}
  #       end
  #   end
  # end
end
