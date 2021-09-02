defmodule FarmbotOS.Lua.Ext.Info do
  @moduledoc """
  Lua extensions for gathering information about a running Farmbot
  """

  alias FarmbotCeleryScript.SysCalls
  alias FarmbotOS.Lua.Util
  alias FarmbotCore.Config

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

  def send_message([kind, message, channels], lua) do
    channels =
      channels
      |> List.wrap()
      |> Enum.map(fn
        {_key, value} -> value
        value -> value
      end)
      |> Enum.map(&String.to_atom/1)

    do_send_message(kind, message, channels, lua)
  end

  @doc "Returns data about the bot's state"
  def read_status([], lua) do
    bot_state = FarmbotCore.BotState.fetch() |> FarmbotCore.BotStateNG.view()

    {[Util.map_to_table(bot_state)], lua}
  end

  def read_status(path, lua) do
    bot_state = FarmbotCore.BotState.fetch() |> FarmbotCore.BotStateNG.view()
    path = List.flatten(path) |> Enum.map(&String.to_atom(&1))

    case get_in(bot_state, path) do
      %{} = map ->
        {[Util.map_to_table(map)], lua}

      other ->
        {[other], lua}
    end
  end

  @doc "Returns the current version of farmbot."
  def fbos_version(_args, lua) do
    {[FarmbotCore.Project.version(), nil], lua}
  end

  @doc "Returns the current firmware version."
  def firmware_version(_args, lua) do
    state = FarmbotCore.BotStateNG.view(FarmbotCore.BotState.fetch())
    v = state.informational_settings.firmware_version
    {[v, nil], lua}
  end

  @doc "Returns the current month"
  def current_month(_args, lua) do
    {[DateTime.utc_now().month], lua}
  end

  @doc "Returns the current hour"
  def current_hour(_args, lua) do
    {[DateTime.utc_now().hour], lua}
  end

  @doc "Returns the current minute"
  def current_minute(_args, lua) do
    {[DateTime.utc_now().minute], lua}
  end

  @doc "Returns the current second"
  def current_second(_args, lua) do
    {[DateTime.utc_now().second], lua}
  end

  def auth_token(_, lua) do
    token = Config.get_config_value(:string, "authorization", "token")
    {[token], lua}
  end

  defp do_send_message(kind, message, channels, lua) do
    result = SysCalls.send_message(kind, "#{message}", channels)

    case result do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end
end
