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

  def get_xyz(_args, lua) do
    read_status(["location_data", "position"], lua)
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

  def utc(["year"], lua), do: {[utc_p().year], lua}
  def utc(["month"], lua), do: {[utc_p().month], lua}
  def utc(["day"], lua), do: {[utc_p().day], lua}
  def utc(["hour"], lua), do: {[utc_p().hour], lua}
  def utc(["minute"], lua), do: {[utc_p().minute], lua}
  def utc(["second"], lua), do: {[utc_p().second], lua}
  def utc(_, lua), do: {[DateTime.to_string(utc_p())], lua}

  def local_time(["year"], lua), do: {[local_time_p().year], lua}
  def local_time(["month"], lua), do: {[local_time_p().month], lua}
  def local_time(["day"], lua), do: {[local_time_p().day], lua}
  def local_time(["hour"], lua), do: {[local_time_p().hour], lua}
  def local_time(["minute"], lua), do: {[local_time_p().minute], lua}
  def local_time(["second"], lua), do: {[local_time_p().second], lua}
  def local_time(_, lua), do: {[DateTime.to_string(local_time_p())], lua}

  defp utc_p() do
    DateTime.utc_now()
  end

  defp local_time_p() do
    tz = FarmbotOS.Asset.device().timezone
    datetime = utc_p()
    Timex.Timezone.convert(datetime, tz)
  end

  @doc "Returns the current year"
  def current_year(_args, lua) do
    {[DateTime.utc_now().year], lua}
  end

  @doc "Returns the current month"
  def current_month(_args, lua) do
    {[DateTime.utc_now().month], lua}
  end

  @doc "Returns the current day"
  def current_day(_args, lua) do
    {[DateTime.utc_now().day], lua}
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

  def get_job([name], lua) do
    get_job_progress([name], lua)
  end

  def set_job_progress([name, args], lua) do
    map = FarmbotOS.Lua.Util.lua_to_elixir(args)

    job = %FarmbotOS.BotState.JobProgress.Percent{
      type: Map.get(map, "type") || "unknown",
      status: Map.get(map, "status") || "Working",
      percent: Map.get(map, "percent") || 0,
      time: Map.get(map, "time") || nil
    }

    FarmbotOS.BotState.set_job_progress(name, job)
    {[], lua}
  end

  def set_job([name], lua) do
    set_job([name, []], lua)
  end

  def set_job([name, args], lua) do
    map = FarmbotOS.Lua.Util.lua_to_elixir(args)
    {[existing_job], _} = get_job_progress([name], lua)
    existing = FarmbotOS.Lua.Util.lua_to_elixir(existing_job) || %{}

    existing_map =
      if Map.get(existing, :status) == "Complete" do
        %{}
      else
        existing
      end

    now = DateTime.to_unix(DateTime.utc_now()) * 1000
    time = Map.get(map, "time") || Map.get(existing_map, :time) || now

    job = %{
      type: Map.get(map, "type") || Map.get(existing_map, :type),
      status: Map.get(map, "status") || Map.get(existing_map, :status),
      percent: Map.get(map, "percent") || Map.get(existing_map, :percent),
      time: time
    }

    set_job_progress([name, FarmbotOS.Lua.Util.map_to_table(job)], lua)
  end

  def complete_job([name], lua) do
    job = %{
      status: "Complete",
      percent: 100
    }

    set_job([name, FarmbotOS.Lua.Util.map_to_table(job)], lua)
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
