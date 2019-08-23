defmodule FarmbotOS.Lua.Ext.Info do
  @moduledoc """
  Lua extensions for gathering information about Farmbot
  """
  alias FarmbotCeleryScript.SysCalls

  @doc """
  # Example Usage

  ## With channels

      farmbot.send_message("info", "hello, world", ["email", "toast"])

  ## No channels

      farmbot.send_message("info", "hello, world")

  """
  def send_message([kind, message], lua) do
    do_send_message(kind, message, [], lua)
  end

  def send_message([kind, message | channels], lua) do
    channels = Enum.map(channels, &String.to_atom/1)
    do_send_message(kind, message, channels, lua)
  end

  @doc "Returns data about the bot's state"
  def read_status([], lua) do
    bot_state = FarmbotCore.BotState.fetch() |> FarmbotCore.BotStateNG.view()

    {[map_to_table(bot_state)], lua}
  end

  def read_status(path, lua) do
    bot_state = FarmbotCore.BotState.fetch() |> FarmbotCore.BotStateNG.view()
    path = List.flatten(path) |> Enum.map(&String.to_atom(&1))

    case get_in(bot_state, path) do
      %{} = map ->
        {[map_to_table(map)], lua}

      other ->
        {[other], lua}
    end
  end

  @doc "Returns the current version of farmbot."
  def version(_args, lua) do
    {[FarmbotCore.Project.version(), nil], lua}
  end

  defp do_send_message(kind, message, channels, lua) do
    case SysCalls.send_message(kind, message, channels) do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  defp map_to_table(map) do
    Enum.map(map, fn
      {key, %{} = value} ->
        {to_string(key), map_to_table(value)}

      {key, value} ->
        {to_string(key), value}
    end)
  end
end
