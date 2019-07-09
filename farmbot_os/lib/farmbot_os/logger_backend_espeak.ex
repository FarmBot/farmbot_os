defmodule LoggerBackendEspeak do
  @moduledoc """
  Logger backend for speaking logs outloud
  """

  @behaviour :gen_event

  @impl :gen_event
  def init(_) do
    exe = System.find_executable("espeak")
    send(self(), {:open, exe})
    {:ok, %{port: nil}}
  end

  @impl :gen_event
  def terminate(_reason, state) do
    if state.port do
      :erlang.port_close(state.port)
    end
  end

  @impl :gen_event
  def handle_event({_level, _pid, {Logger, _msg, _timestamp, _meta}}, %{port: nil} = state) do
    {:ok, state}
  end

  def handle_event({_level, _pid, {Logger, msg, _timestamp, meta}}, %{port: espeak} = state) do
    should_espeak? =
      meta[:channels] == :espeak ||
        Enum.find(meta[:channels] || [], fn
          :espeak -> true
          "espeak" -> true
          _ -> false
        end)

    if should_espeak? do
      _ = Port.command(espeak, IO.iodata_to_binary(msg) <> "\n")
    end

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_info({:open, nil}, state) do
    {:ok, state}
  end

  def handle_info({:open, exe}, state) do
    port = :erlang.open_port({:spawn_executable, to_charlist(exe)}, [:exit_status])
    Port.command(port, "\n")
    {:ok, %{state | port: port}}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_call(_, state) do
    {:ok, :ok, state}
  end
end
