defmodule Farmbot.OS.IOLayer.SendMessage do
  @moduledoc false

  alias Farmbot.Firmware
  @root_regex ~r/{{\s*[\w\.]+\s*}}/
  @extract_reg ~r/[\w\.]+/

  def execute(%{message: templ, message_type: type}, channels) do
    type = String.to_existing_atom(type)

    meta = [
      channels:
        Enum.map(channels, fn %{kind: :channel, args: %{channel_name: nm}} ->
          nm
        end)
    ]

    case render(templ) do
      {:ok, message} ->
        Farmbot.Logger.dispatch_log(__ENV__, type, 1, message, meta)
        :ok

      er ->
        er
    end
  end

  def render(templ) do
    with {:ok, {_, {:report_position, pos}}} <- Firmware.request({:position_read, []}),
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

  def pins(nums, acc \\ [])

  def pins([p | rest], acc) do
    case Firmware.request({:pin_read, [p: p]}) do
      {:ok, {_, {:report_pin_value, [p: ^p, v: v]}}} ->
        acc = Keyword.put(acc, :"pin#{p}", v)
        pins(rest, acc)

      er ->
        er
    end
  end

  def pins([], acc), do: {:ok, acc}
end
