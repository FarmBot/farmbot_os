defmodule Farmbot.Transport.Supervisor do
  @moduledoc """
    Supervises services that communicate with the outside world.
  """
  use Supervisor
  alias Farmbot.Context
  use Farmbot.DebugLog

  case Mix.env do
    :test ->
      defp setup_env do
        Mix.shell.info [:green, "Deleting environment!!!!!!"]
        Application.delete_env(:farmbot, :transports)
        Application.put_env(:farmbot, :transports, [])
        :ok
      end
    _ ->
      defp setup_env do
        :ok
      end
  end

  def init(ctx) do
    :ok = setup_env()
    transports = Application.get_env(:farmbot, :transports)
    children   = [ default_transport(ctx) | build_children(transports, ctx)]
    opts       = [strategy: :one_for_one]
    supervise(children, opts)
  end

  defp default_transport(%Context{} = ctx) do
    worker(Farmbot.Transport,
      [ctx, [name: Farmbot.Transport]],
        restart: :permanent)
  end

  @doc """
    Starts all the transports.
  """
  def start_link(%Context{} = ctx, opts),
    do: Supervisor.start_link(__MODULE__, ctx, opts)

  @spec build_children([atom], Context.t) :: [Supervisor.child]
  defp build_children(transports, %Context{} = context) do
    Enum.map(transports, fn(t) ->
      case t do
        module when is_atom(module) ->
          debug_log "starting tansport: #{module}"
          worker(module, [context, []], restart: :permanent)
        {module, opts} when is_atom(module) ->
          debug_log "starting transport: #{module} with opts: #{inspect opts}"
          worker(module, [context, opts], restart: :permanent)
      end
    end)
  end
end
