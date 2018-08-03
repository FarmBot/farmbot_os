defmodule Farmbot.AutoSyncTask do
  @moduledoc false
  require Farmbot.Logger

  @rpc %{
    kind: :rpc_request,
    args: %{label: "auto_sync_task"},
    body: [
      %{kind: :sync, args: %{}}
    ]
  }

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :maybe_auto_sync, opts},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  def maybe_auto_sync() do
    if Farmbot.Config.get_config_value(:bool, "settings", "auto_sync") do
      Farmbot.CeleryScript.rpc_request(@rpc, &handle_rpc/1)
    end
    :ignore
  end

  @doc false
  def handle_rpc(%{kind: :rpc_ok}), do: :ok
  def handle_rpc(%{kind: :rpc_error, body: [%{args: %{message: msg}}]}) do
    Farmbot.Logger.error 1, "AutoSyncTask failed: #{msg}"
  end
end
