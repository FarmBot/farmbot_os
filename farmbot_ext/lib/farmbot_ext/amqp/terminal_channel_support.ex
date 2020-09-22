defmodule FarmbotExt.AMQP.TerminalChannelSupport do
  use AMQP
  alias FarmbotExt.AMQP.ConnectionWorker
  @exchange "amq.topic"

  def get_channel(bot) do
    key = "bot.#{bot}.terminal_input"
    name = bot <> "_terminal"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         %{pid: channel_pid} <- chan,
         _ <- Process.link(channel_pid),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, name, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, name),
         :ok <- Queue.bind(chan, name, @exchange, routing_key: key),
         {:ok, _tag} <- Basic.consume(chan, name, self(), no_ack: true) do
      {:ok, chan}
    else
      error -> error
    end
  end

  def shell_opts do
    [
      [
        dot_iex_path:
          [".iex.exs", "~/.iex.exs", "/etc/iex.exs"]
          |> Enum.map(&Path.expand/1)
          |> Enum.find("", &File.regular?/1)
      ]
    ]
  end
end
