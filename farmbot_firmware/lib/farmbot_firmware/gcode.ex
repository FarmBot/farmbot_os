defmodule Farmbot.Firmware.GCODE do
  alias Farmbot.Firmware.Param
  @type tag() :: nil | binary()
  @type kind() :: atom()
  @type args() :: [arg]
  # TODO(Connor) - narrow this
  @type arg() :: any()

  @spec decode(binary) :: {tag, {kind, args}}
  def decode(binary_with_q) when is_binary(binary_with_q) do
    code = String.split(binary_with_q, " ")
    {tag, [kind | args]} = extract_tag(code)
    {tag, do_decode(kind, args)}
  end

  @spec encode({tag, {kind, args}}) :: binary()
  def encode({nil, {kind, args}}) do
    do_encode(kind, args)
  end

  def encode({tag, {kind, args}}) do
    str = do_encode(kind, args)
    str <> " Q" <> tag
  end

  def do_encode(:write_paramater, [{param, value}]) do
    param_id = Param.encode(param)
    binary_float = :erlang.float_to_binary(value, decimals: 2)
    "F22 P#{param_id} V#{binary_float}"
  end

  def do_encode(:read_all_paramaters, []) do
    "F20"
  end

  @doc false
  @spec do_decode(binary(), [binary()]) :: {kind(), args()}
  def do_decode("R00", []), do: {:report_idle, []}
  def do_decode("R01", []), do: {:report_begin, []}
  def do_decode("R02", []), do: {:report_success, []}
  def do_decode("R03", []), do: {:report_error, []}
  def do_decode("R04", []), do: {:report_busy, []}

  def do_decode("R05", xyz), do: {:report_axis_state, decode_axis_state(xyz)}
  def do_decode("R06", xyz), do: {:report_calibration_state, decode_calibration_state(xyz)}

  def do_decode("R07", []), do: {:report_retry, []}
  def do_decode("R08", args), do: {:report_echo, decode_echo(Enum.join(args, " "))}
  def do_decode("R09", []), do: {:report_invalid, []}

  def do_decode("R11", []), do: {:report_home_complete, [:x]}
  def do_decode("R12", []), do: {:report_home_complete, [:y]}
  def do_decode("R13", []), do: {:report_home_complete, [:z]}

  def do_decode("R15", x), do: {:report_position, decode_xyzs(x)}
  def do_decode("R16", y), do: {:report_position, decode_xyzs(y)}
  def do_decode("R17", z), do: {:report_position, decode_xyzs(z)}

  def do_decode("R20", []), do: {:report_paramaters_complete, []}

  def do_decode("R21", pv), do: {:report_paramater, decode_pv(pv)}
  def do_decode("R23", pv), do: {:report_calibration_paramater, decode_pv(pv)}
  def do_decode("R33", pv), do: {:report_status_value, decode_status_value(pv)}
  def do_decode("R41", pv), do: {:report_pin_value, decode_pin_value(pv)}

  def do_decode("R71", []), do: {:report_axis_timeout, [:x]}
  def do_decode("R72", []), do: {:report_axis_timeout, [:y]}
  def do_decode("R73", []), do: {:report_axis_timeout, [:z]}

  def do_decode("R81", xxyyzz), do: {:report_end_stops, decode_end_stops(xxyyzz)}
  def do_decode("R82", xyz), do: {:report_position, decode_xyzs(xyz)}

  def do_decode("R83", [version]), do: {:report_version, [version]}

  def do_decode("R84", xyz), do: {:report_encoders_scaled, decode_xyzs(xyz)}
  def do_decode("R85", xyz), do: {:report_encoders_raw, decode_xyzs(xyz)}

  def do_decode("R87", []), do: {:report_emergency_lock, []}
  def do_decode("R88", []), do: {:report_no_config, []}
  def do_decode("R99", debug), do: {:report_debug_message, Enum.join(debug, " ")}

  def do_decode(kind, args) do
    {:unknown, [kind | args]}
  end

  @spec extract_tag([binary()]) :: {tag(), [binary()]}
  def extract_tag(list) when is_list(list) do
    with {"Q" <> bin_tag, list} when is_list(list) <- List.pop_at(list, -1) do
      {bin_tag, list}
    else
      # if there was no Q code provided
      {_, data} when is_list(data) -> {nil, list}
    end
  end

  defp decode_xyzs(list, acc \\ [])

  defp decode_xyzs([<<arg::binary-1, val::binary>> | rest], acc) do
    arg =
      arg
      |> String.downcase()
      |> String.to_existing_atom()

    case Float.parse(val) do
      {num, ""} ->
        decode_xyzs(rest, Keyword.put(acc, arg, num))

      _ ->
        case Integer.parse(val) do
          {num, ""} -> decode_xyzs(rest, Keyword.put(acc, arg, num / 1))
          _ -> decode_xyzs(rest, acc)
        end
    end
  end

  # This is sort of order dependent and not exactly correct.
  # It should ensure the order is [x: _, y: _, z: _]
  defp decode_xyzs([], acc), do: Enum.reverse(acc)

  defp decode_axis_state(list) do
    args = decode_xyzs(list)

    Enum.map(args, fn {axis, value} ->
      case value do
        0.0 -> {axis, :idle}
        1.0 -> {axis, :begin}
        2.0 -> {axis, :accelerate}
        3.0 -> {axis, :cruise}
        4.0 -> {axis, :decelerate}
        5.0 -> {axis, :stop}
        6.0 -> {axis, :crawl}
      end
    end)
  end

  defp decode_calibration_state(list) do
    args = decode_xyzs(list)

    Enum.map(args, fn {axis, value} ->
      case value do
        0.0 -> {axis, :idle}
        1.0 -> {axis, :home}
        2.0 -> {axis, :end}
      end
    end)
  end

  @spec decode_end_stops([binary()], Keyword.t()) :: Keyword.t()
  defp decode_end_stops(list, acc \\ [])

  defp decode_end_stops(
         [<<arg::binary-1, "A", val0::binary>>, <<arg::binary-1, "B", val1::binary>> | rest],
         acc
       ) do
    dc = String.downcase(arg)

    acc =
      acc ++
        [
          {:"#{dc}a", String.to_integer(val0)},
          {:"#{dc}b", String.to_integer(val1)}
        ]

    decode_end_stops(rest, acc)
  end

  defp decode_end_stops([], acc), do: acc

  defp decode_pv(["P" <> param_id, "V" <> value]) do
    param = Param.decode(String.to_integer(param_id))
    {value, ""} = Float.parse(value)
    [{param, value}]
  end

  defp decode_pin_value(["P" <> pin_number, "V" <> value]) do
    [{String.to_integer(pin_number), String.to_integer(value)}]
  end

  defp decode_status_value(["P" <> status_id, "V" <> value]) do
    [{String.to_integer(status_id), String.to_integer(value)}]
  end

  @spec decode_echo(binary()) :: [binary()]
  defp decode_echo(str) when is_binary(str) do
    [_, echo | _] = String.split(str, "*", parts: 3)
    [String.trim(echo)]
  end
end
