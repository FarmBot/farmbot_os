defmodule FarmbotOS.Lua.CeleryScript do
  alias FarmbotCeleryScript.SysCalls

  @doc """
  Returns a table containing position data

  ## Example

      print("x", farmbot.get_position().x);
      print("y", farmbot.get_position()["y"]);
      position = farmbot.get_position();
      print("z", position.z);
  """
  def get_position(["x"], lua) do
    case SysCalls.get_current_x() do
      x when is_number(x) ->
        {[x, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_position(["y"], lua) do
    case SysCalls.get_current_y() do
      y when is_number(y) ->
        {[y, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_position(["z"], lua) do
    case SysCalls.get_current_z() do
      z when is_number(z) ->
        {[z, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def get_position(_args, lua) do
    with x when is_number(x) <- SysCalls.get_current_x(),
         y when is_number(y) <- SysCalls.get_current_y(),
         z when is_number(z) <- SysCalls.get_current_z() do
      {[[{"x", x}, {"y", y}, {"z", z}], nil], lua}
    else
      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  @doc """
  Returns a table with pins data

  ## Example

    print("pin9", farmbot.get_pin()["9"]);
  """
  def get_pins(_args, lua) do
    case do_get_pins(Enum.to_list(0..69)) do
      {:ok, contents} ->
        {[contents, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

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

  @doc """
  Returns help docs about a function.
  """
  def help([function_name], lua) do
    function_name = String.to_atom(function_name)

    case Code.fetch_docs(__MODULE__) do
      {:docs_v1, _, _, _, _, _, docs} ->
        docs =
          Enum.find_value(docs, fn
            {{:function, ^function_name, _arity}, _, _, %{"en" => docs}, _} ->
              IO.iodata_to_binary(docs)

            _other ->
              false
          end)

        if docs,
          do: {[docs, nil], lua},
          else: {[nil, "docs not found"], lua}

      {:error, reason} ->
        {[nil, reason], lua}
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

  defp do_get_pins(nums, acc \\ [])

  defp do_get_pins([p | rest], acc) do
    case FarmbotFirmware.request({:pin_read, [p: p]}) do
      {:ok, {_, {:report_pin_value, [p: ^p, v: v]}}} ->
        do_get_pins(rest, [{to_string(p), v} | acc])

      er ->
        er
    end
  end

  defp do_get_pins([], acc), do: {:ok, Enum.reverse(acc)}
end
