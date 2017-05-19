defmodule Farmbot.Transport.Supervisor do
  @moduledoc """
    Supervises services that communicate with the outside world.
  """
  use Supervisor
  alias Farmbot.Context

  env = Mix.env()

  def init(context) do

    if unquote(env) == :test do
      Mix.shell.info [:green, "Deleting environment!!!!!!"]
      Application.delete_env(:farmbot, :transports)
      Application.put_env(:farmbot, :transports, [])
    end

    transports = Application.get_env(:farmbot, :transports)
    children   = build_children(transports, context)
    opts       = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Starts all the transports.
  """
  def start_link(context, opts),
    do: Supervisor.start_link(__MODULE__, context, opts)

  @spec build_children([atom], Context.t) :: [Supervisor.child]
  defp build_children(transports, %Context{} = context) do
    [
      worker(Farmbot.Transport,
        [context, [name: Farmbot.Transport]],
        restart: :permanent)
    ] ++
    Enum.map(transports, fn(t) ->
      case t do
        module when is_atom(module) ->
          worker(module, [context], restart: :permanent)
        {module, opts} ->
          worker(module, [context, [opts]], restart: :permanent)
      end
    end)
  end
end
