defmodule FarmbotOS.MQTT.TerminalHandlerSupport do
  alias FarmbotOS.MQTT

  @default_dot_iex [".iex.exs", "~/.iex.exs", "/etc/iex.exs"]

  def start_iex(state) do
    process = Process.whereis(:ex_tty_handler_farmbot)

    if process do
      %{state | iex_pid: process}
    else
      opts = [
        type: :elixir,
        shell_opts: shell_opts(),
        handler: self(),
        name: :ex_tty_handler_farmbot
      ]

      {:ok, iex_pid} = ExTTY.start_link(opts)
      ExTTY.window_change(iex_pid, 84, 24)
      %{state | iex_pid: iex_pid}
    end
  end

  def stop_iex(%{iex_pid: nil} = state), do: state

  def stop_iex(%{iex_pid: iex} = state) do
    _ = Process.unlink(iex)
    :ok = GenServer.stop(iex, :normal, 10_000)
    %{state | iex_pid: nil}
  end

  def tty_send(state, data) do
    MQTT.publish(state.client_id, "bot/#{state.username}/terminal_output", data)
  end

  def shell_opts do
    [
      [
        dot_iex_path:
          @default_dot_iex
          |> Enum.map(&Path.expand/1)
          |> Enum.find("", &File.regular?/1)
      ]
    ]
  end
end
