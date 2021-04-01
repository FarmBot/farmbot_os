defmodule FarmbotOS.SysCalls.SendMessage do
  @moduledoc false

  alias FarmbotCore.Firmware
  @root_regex ~r/{{\s*[\w\.]+\s*}}/
  @extract_reg ~r/[\w\.]+/

  def send_message(type, templ, channels) do
    type = String.to_existing_atom(type)

    meta = [
      channels: channels
    ]

    case render(templ) do
      {:ok, message} ->
        FarmbotCore.Logger.dispatch_log(__ENV__, type, 1, message, meta)
        # Give LogChannel time to catch up and ingest logs.
        # Removing this line will result in non-deterministic
        # loss of duplicate logs or general "funny business"
        # when executing two consecutive SEND MESSAGE blocks. :(
        Process.sleep(100)
        :ok

      er ->
        er
    end
  end

  def render(templ) do
    with {:ok, pos} <- pos(),
         {:ok, pins} <- pins(),
         {:ok, special} <- special(),
         env <- Keyword.merge(pos, pins),
         env <- Keyword.merge(env, special) do
      env = Map.new(env, fn {k, v} -> {to_string(k), to_string(v)} end)

      # Mini Mustache parser
      data =
        Regex.scan(@root_regex, templ)
        |> Map.new(fn [itm] ->
          [indx] = Regex.run(@extract_reg, itm)
          {itm, env[indx]}
        end)

      rendered =
        Regex.replace(@root_regex, templ, fn d ->
          Map.get(data, d) || ""
        end)

      {:ok, rendered}
    end
  end

  def pos do
    [x: x, y: y, z: z] = FarmbotOS.SysCalls.get_cached_position()

    {:ok,
     [
       x: FarmbotCeleryScript.FormatUtil.format_float(x),
       y: FarmbotCeleryScript.FormatUtil.format_float(y),
       z: FarmbotCeleryScript.FormatUtil.format_float(z)
     ]}
  end

  def pins() do
    {:ok,
     FarmbotCore.BotState.fetch().pins
     |> Map.new()
     |> Enum.map(fn {p, %{value: v}} ->
       {:"pin#{p}", FarmbotCeleryScript.FormatUtil.format_float(v)}
     end)}
  end

  def special() do
    {:ok,
     [
       {:NULL, nil},
       {:CURRENT_TIME, DateTime.utc_now()}
     ]}
  end
end
