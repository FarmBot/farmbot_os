defmodule FarmbotOS.Lua.Info do
  @moduledoc """
  Lua extensions for gathering information about a running Farmbot
  """

  alias FarmbotOS.Celery.SysCallGlue
  alias FarmbotOS.Lua.Util
  alias FarmbotOS.Config

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

  def debug([message], lua), do: send_message(["debug", message], lua)
  def toast([message], lua), do: send_message(["info", message, "toast"], lua)

  def toast([message, type], lua),
    do: send_message([type, message, "toast"], lua)

  @doc "Returns data about the bot's state"
  def read_status([], lua) do
    bot_state = FarmbotOS.BotState.fetch() |> FarmbotOS.BotStateNG.view()

    {[Util.map_to_table(bot_state)], lua}
  end

  def read_status(path, lua) do
    bot_state = FarmbotOS.BotState.fetch() |> FarmbotOS.BotStateNG.view()
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
    {[FarmbotOS.Project.version(), nil], lua}
  end

  @doc "Returns the current firmware version."
  def firmware_version(_args, lua) do
    state = FarmbotOS.BotStateNG.view(FarmbotOS.BotState.fetch())
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

  def get_job_progress([name], lua) do
    job = Map.get(FarmbotOS.BotState.fetch().jobs, name)
    {[job], lua}
  end

  def set_job_progress([name, args], lua) do
    map = FarmbotOS.Lua.Util.lua_to_elixir(args)

    job = %FarmbotOS.BotState.JobProgress.Percent{
      type: Map.get(map, "type") || "unknown",
      status: Map.get(map, "status") || "working",
      percent: Map.get(map, "percent") || 0,
      time: Map.get(map, "time") || nil
    }

    FarmbotOS.BotState.set_job_progress(name, job)
    {[], lua}
  end

  defp do_send_message(kind, message, channels, lua) do
    result = SysCallGlue.send_message(kind, "#{message}", channels)

    case result do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end
end
