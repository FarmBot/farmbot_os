defmodule FarmbotOS.Lua.Ext.Firmware do
  alias FarmbotCeleryScript.SysCalls

  def calibrate([axis], lua) when axis in ["x", "y", "z"] do
    case SysCalls.calibrate(axis) do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def emergency_lock(_, lua) do
    case SysCalls.emergency_lock() do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def emergency_unlock(_, lua) do
    case SysCalls.emergency_unlock() do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def find_home([axis], lua) when axis in ["x", "y", "z"] do
    case SysCalls.find_home(axis) do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def home([axis, speed], lua) when axis in ["x", "y", "z"] do
    case SysCalls.home(axis, speed) do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  @doc "Moves in a straight line to a location"
  def move_absolute([x, y, z], lua) when is_number(x) and is_number(y) and is_number(z) do
    case SysCalls.move_absolute(x, y, z, 100) do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end

  def move_absolute([table], lua) when is_list(table) do
    axis_finder = fn
      axis, {axis, nil} -> apply(SysCalls, :"get_current_#{axis}", [])
      axis, {axis, value} -> value
      _, {_axis, _value} -> false
    end

    x = Enum.find_value(table, &axis_finder.("x", &1))
    y = Enum.find_value(table, &axis_finder.("y", &1))
    z = Enum.find_value(table, &axis_finder.("z", &1))
    move_absolute([x, y, z], lua)
  end

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

  def coordinate([x, y, z], lua) when is_number(x) and is_number(y) and is_number(z) do
    {[{"x", x}, {"y", y}, {"z", z}], lua}
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
