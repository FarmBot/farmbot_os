defmodule FarmbotOS.SysCalls.SendMessage do
  alias FarmbotFirmware
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
        :ok

      er ->
        er
    end
  end

  def render(templ) do
    with {:ok, pos} <- pos(),
         {:ok, pins} <- pins(Enum.to_list(0..69)),
         env <- Keyword.merge(pos, pins) do
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
    case FarmbotFirmware.request({:position_read, []}) do
      {:ok, {_, {:report_position, [x: x, y: y, z: z]}}} ->
        {:ok,
         [
           x: FarmbotCeleryScript.FormatUtil.format_float(x),
           y: FarmbotCeleryScript.FormatUtil.format_float(y),
           z: FarmbotCeleryScript.FormatUtil.format_float(z)
         ]}
    end
  end

  def pins(nums, acc \\ [])

  def pins([p | rest], acc) do
    case FarmbotFirmware.request({:pin_read, [p: p]}) do
      {:ok, {_, {:report_pin_value, [p: ^p, v: v]}}} ->
        v = FarmbotCeleryScript.FormatUtil.format_float(v)
        acc = Keyword.put(acc, :"pin#{p}", v)
        pins(rest, acc)

      er ->
        er
    end
  end

  def pins([], acc), do: {:ok, acc}
end
