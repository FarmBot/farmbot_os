defmodule FarmbotOS.Configurator.LoggerBackend do
  @moduledoc """
  Logger backend for LoggerSockets to subscribe too
  """

  @behaviour :gen_event

  @doc "register self() for logger events to be delivered"
  def register() do
    {:ok, _} = Registry.register(__MODULE__, :dispatch, self())
    :ok
  end

  @impl :gen_event
  def init(_) do
    case Registry.start_link(keys: :duplicate, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end

    {:ok, %{}}
  end

  @impl :gen_event
  def terminate(_reason, _state) do
    :ok
  end

  @impl :gen_event
  def handle_event(
        {_level, _pid, {Logger, _msg, _timestamp, _meta}} = log,
        state
      ) do
    Registry.dispatch(__MODULE__, :dispatch, fn entries ->
      for {pid, _} <- entries do
        send(pid, log)
      end
    end)

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_info(_, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_call(_, state) do
    {:ok, :ok, state}
  end
end
