defmodule FarmbotExt.AMQP.TerminalChannelSupport do
  use AMQP
  alias FarmbotExt.AMQP.Support
  @exchange "amq.topic"

  def get_channel(bot) do
    key = "bot.#{bot}.terminal_input"
    name = bot <> "_terminal"

    with {:ok, {_conn, chan}} <- Support.create_queue(name),
         :ok <- Support.bind_and_consume(chan, name, @exchange, key) do
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

  def tty_send(bot_name, amqp_channel, data) do
    chan = "bot.#{bot_name}.terminal_output"
    AMQP.Basic.publish(amqp_channel, "amq.topic", chan, data)
  end
end
