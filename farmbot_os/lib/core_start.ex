defmodule Farmbot.System.CoreStart do
  @moduledoc false
  use Supervisor
  require Logger

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    :ok = start_core_app(Farmbot.BootState.read())
    Supervisor.init([], [strategy: :one_for_one])
  end

  defp start_core_app(state) do
    case Application.ensure_all_started(:farmbot_core) do
      {:ok, _} ->
        Farmbot.BootState.write(:UPANDRUNNING)
        :ok
      {:error, {:farmbot_core, {{:shutdown, {:failed_to_start_child, child, reason}}, _}}} ->
        msg = "Failed to start farmbot_core while in state: #{inspect state} child: #{child} => #{inspect reason}"
        maybe_reset(msg)
        :ok
    end
  end

  defp maybe_reset(msg) do
    Farmbot.System.factory_reset(msg)
  end
end
